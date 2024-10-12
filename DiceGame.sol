// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DiceGame {
    address public owner;
    uint256 public minBet;   // Minimum bet
    uint256 public maxBet;   // Maximum bet

    enum BetType { High, Low, Total, Pair, Triple }

    struct Bet {
        uint256 amount;        // Bet amount
        BetType betType;       // Bet type (High, Low, Total, Pair, Triple)
        uint8[] numbers;       // Numbers chosen (if applicable)
    }

    mapping(address => Bet) public bets;

    event DiceRolled(address indexed player, uint256[3] diceResults, uint256 total, bool win, uint256 payout);
    event BetPlaced(address indexed player, uint256 amount, BetType betType, uint8[] numbers);
    event BetLimitsChanged(uint256 newMinBet, uint256 newMaxBet);

    // Constructor
    constructor(uint256 _minBet, uint256 _maxBet) {
        owner = msg.sender;
        minBet = _minBet;
        maxBet = _maxBet;
    }

    // Modifier to ensure only the owner can change bet limits
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can modify bet limits.");
        _;
    }

    // Function to set bet limits (min and max)
    function setBetLimits(uint256 _newMinBet, uint256 _newMaxBet) external onlyOwner {
        require(_newMinBet > 0, "Minimum bet must be greater than 0.");
        require(_newMaxBet > _newMinBet, "Maximum bet must be greater than minimum bet.");
        minBet = _newMinBet;
        maxBet = _newMaxBet;
        emit BetLimitsChanged(_newMinBet, _newMaxBet);
    }

    // Function to place a bet
    function placeBet(BetType _betType, uint8[] memory _numbers) external payable {
        require(msg.value >= minBet, "Bet must be at least the minimum.");
        require(msg.value <= maxBet, "Bet exceeds the maximum.");
        require(bets[msg.sender].amount == 0, "You already placed a bet.");

        bets[msg.sender] = Bet({
            amount: msg.value,
            betType: _betType,
            numbers: _numbers
        });

        emit BetPlaced(msg.sender, msg.value, _betType, _numbers);
    }

    // Function to roll dice and generate randomness using blockhash and timestamp
    function rollDice() external {
        require(bets[msg.sender].amount > 0, "You haven't placed a bet.");

        Bet memory currentBet = bets[msg.sender];
        uint256 contractBalance = address(this).balance;

        // Calculate the payout based on the type of bet
        uint256 payout = getPayout(currentBet);
        require(contractBalance >= payout, "Insufficient contract balance to pay out.");

        // Generate random number using blockhash and block.timestamp
        uint256 randomValue = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender))) % 216; // 216 possible outcomes (6*6*6 for three dice)

        uint256[3] memory diceResults = [
            (randomValue % 6) + 1, 
            ((randomValue / 6) % 6) + 1,
            ((randomValue / 36) % 6) + 1
        ];

        uint256 total = diceResults[0] + diceResults[1] + diceResults[2];

        // Determine if the player wins based on the bet type
        bool win = false;
        if (currentBet.betType == BetType.High && total >= 11) {
            win = true;
            payout = currentBet.amount * 2;
        } else if (currentBet.betType == BetType.Low && total <= 10) {
            win = true;
            payout = currentBet.amount * 2;
        } else if (currentBet.betType == BetType.Total) {
            uint8 chosenTotal = currentBet.numbers[0];
            if (total == chosenTotal) {
                win = true;
                payout = currentBet.amount * 6;
            }
        } else if (currentBet.betType == BetType.Pair) {
            uint8 chosenPair1 = currentBet.numbers[0];
            uint8 chosenPair2 = currentBet.numbers[1];
            if ((diceResults[0] == chosenPair1 && diceResults[1] == chosenPair2) ||
                (diceResults[0] == chosenPair2 && diceResults[1] == chosenPair1)) {
                win = true;
                payout = currentBet.amount * 6;
            }
        } else if (currentBet.betType == BetType.Triple) {
            uint8 chosenTriple = currentBet.numbers[0];
            if (diceResults[0] == chosenTriple && diceResults[1] == chosenTriple && diceResults[2] == chosenTriple) {
                win = true;
                payout = currentBet.amount * 180;
            }
        }

        // Transfer the payout if the player wins, otherwise just notify the result
        if (win) {
            payable(msg.sender).transfer(payout);
        } else {
            payout = 0;
        }

        emit DiceRolled(msg.sender, diceResults, total, win, payout);
        delete bets[msg.sender];  // Reset the player's bet after the roll
    }

    // Get the payout based on the bet type
    function getPayout(Bet memory currentBet) internal pure returns (uint256) {
        if (currentBet.betType == BetType.High || currentBet.betType == BetType.Low) {
            return currentBet.amount * 2;
        } else if (currentBet.betType == BetType.Total) {
            return currentBet.amount * 6;
        } else if (currentBet.betType == BetType.Pair) {
            return currentBet.amount * 6;
        } else if (currentBet.betType == BetType.Triple) {
            return currentBet.amount * 180;
        }
        return 0;
    }

    // Function for the owner to withdraw ETH from the contract
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance.");
        payable(msg.sender).transfer(_amount);
    }

    // Fallback function to receive ETH deposits into the contract
    receive() external payable {}
}
