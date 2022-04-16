pragma solidity >=0.7.2 <0.9.0;

contract SicboContract {
    modifier onlyOwner {
        require(msg.sender == owner, "You don't have permission update award");
        _;
    }

    enum MethodBet {
        HILOW,
        DOU,
        TRIAD,
        TOTAL,
        COUPLE,
        NUMBER
    }

    struct Bet {
        uint8 betNumber;
        uint8 betSecondNumber;
        uint256 betMoney;
        MethodBet methodBet;
    }

    struct GameResult {
        address player;
        Bet[] Bets;
        uint8 dice1;
        uint8 dice2;
        uint8 dice3;
        uint256 winMoney;
    }

    struct DataValid {
        uint256 totalPay;
        uint256 totalReceive;
    }

    struct Award {
        uint8 hiLow;
        uint8 dou;
        uint8 triad;
        mapping(uint8 => uint) total;
        uint8 couple;        
        uint8 num;
    }

    address private owner;
    Award public award;

    constructor() {
        owner = msg.sender;
        award.hiLow = 1;
        award.dou = 11;
        award.triad = 180;
        award.total[4] = 50;
        award.total[5] = 18;
        award.total[6] = 14;
        award.total[7] = 12;
        award.total[8] = 8;
        award.total[9] = 6;
        award.total[10] = 6;
        award.total[11] = 6;
        award.total[12] = 6;
        award.total[13] = 8;
        award.total[14] = 12;
        award.total[15] = 14;
        award.total[16] = 18;
        award.total[17] = 50;
        award.couple = 6;
        award.num = 1;
    }

    function desposit(uint256 amount) external payable {
        require(msg.value == amount, "Don't have enough money");
    }

    function withdraw(uint256 amount) public {
        require(msg.sender == owner, "You can't withdraw money");
        require(address(this).balance >= amount, "Don't have enough money");
        payable(msg.sender).transfer(amount);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function updateHiLoAward(uint8 val) public onlyOwner {
        award.hiLow = val;
    }

    function updateDouAward(uint8 val) public onlyOwner {
        award.dou = val;
    }

    function updateTriadAward(uint8 val) public onlyOwner {
        award.triad = val;
    }

    function updateTotalAward(uint8 index, uint8 val) public onlyOwner {
        award.total[index] = val;
    }

    function updateCoupleAward(uint8 val) public onlyOwner {
        award.couple = val;
    }

    function updateNumberAward(uint8 val) public onlyOwner {
        award.num = val;
    }

    function randomNum() private returns(uint8) {
        return (uint8(uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))))%10) + 1;
    }

    function rollDice() internal returns(uint8) {
       uint8 rs = randomNum();
        if(rs > 6) {
            rs = rs / 2;
        }
        return rs;
    }

    function checkRule(Bet[] memory bets) internal returns(DataValid memory) {
        uint256 totalPay = 0;
        uint256 totalReceive = 0;

        for(uint8 i = 0; i < bets.length; i++) {
            require(bets[i].betMoney > 0, "BetMoney must great than 0");
            if(bets[i].methodBet == MethodBet.HILOW) {
                require(bets[i].betNumber == 0 || bets[i].betNumber == 1, "BetNumber must is 0 or 1");
                totalPay+= bets[i].betMoney * (award.hiLow + 1);
            } else if(bets[i].methodBet == MethodBet.DOU) {
                require(bets[i].betNumber > 0 && bets[i].betNumber < 7, "BetNumber must from 1 to 6");
                totalPay+= bets[i].betMoney * (award.dou + 1);
            } else if(bets[i].methodBet == MethodBet.TRIAD) {
                require(bets[i].betNumber > 0 && bets[i].betNumber < 7, "BetNumber must from 1 to 6");
                totalPay+= bets[i].betMoney * (award.triad + 1);
            } else if(bets[i].methodBet == MethodBet.TOTAL) {
                require(bets[i].betNumber > 3 && bets[i].betNumber < 18, "BetNumber must from 4 to 17");
                totalPay+= bets[i].betMoney * (award.total[bets[i].betNumber] + 1);
            } else if(bets[i].methodBet == MethodBet.COUPLE) {
                require(bets[i].betNumber > 0 && bets[i].betNumber < 7, "BetNumber must from 1 to 6");
                require(bets[i].betSecondNumber > 0 && bets[i].betNumber < 7, "BetSecondNumber must from 1 to 6");
                totalPay+= bets[i].betMoney * (award.couple + 1);
            } else if(bets[i].methodBet == MethodBet.NUMBER) {
                require(bets[i].betNumber > 0 && bets[i].betNumber < 7, "BetNumber must from 1 to 6");
                totalPay+= bets[i].betMoney * (award.num * 4);
            }
            // if(bets[i].methodBet == MethodBet.HILOW) {
            //     require(bets[i].betNumber == 0 || bets[i].betNumber == 1, "BetNumber must is 0 or 1");
            // } else if(bets[i].methodBet == MethodBet.TOTAL) {
            //     require(bets[i].betNumber > 3 && bets[i].betNumber < 18, "BetNumber must from 4 to 17");
            // } else if(bets[i].methodBet == MethodBet.COUPLE) {
            //     require(bets[i].betNumber > 0 && bets[i].betNumber < 7, "BetNumber must from 1 to 6");
            //     require(bets[i].betSecondNumber > 0 && bets[i].betNumber < 7, "BetSecondNumber must from 1 to 6");
            // } else {
            //     require(bets[i].betNumber > 0 && bets[i].betNumber < 7, "BetNumber must from 1 to 6");
            // }
            totalReceive += bets[i].betMoney;
        }
        require(totalReceive == msg.value, "Bet is not valid");
        require(address(this).balance > totalPay, "Dealer don't have enough to money");

        return DataValid(totalPay, totalReceive);
    }

    function countDice(uint8 num, uint8[3] memory dices) private pure returns (uint8) {
        uint8 count = 0;
        for(uint8 i = 0; i < dices.length; i++) {
            if(num == dices[i]) {
                count++;
            }
        }
        return count;
    }

    function playerWinner(Bet[] memory bets, uint8[3] memory dices) internal returns(uint256) {
        uint256 totalPay = 0;
        uint8 sumDice = 0;
         for(uint8 i = 0; i < dices.length; i++) {
            sumDice += dices[i];
        }
        for(uint8 i = 0; i < bets.length; i++) {
            if(bets[i].methodBet == MethodBet.HILOW) {
                uint8 c = countDice(dices[1], dices);
                if(((sumDice >=4 && sumDice <= 10 && bets[i].betNumber == 0) 
                    || (sumDice >= 11 && sumDice <= 17 && bets[i].betNumber == 1)) && c < 3
                ) {
                    totalPay+= bets[i].betMoney * (award.hiLow + 1);
                }                
            } else if(bets[i].methodBet == MethodBet.DOU) {
                uint8 c = countDice(bets[i].betNumber, dices);
                if(2 == c) {
                    totalPay+= bets[i].betMoney * (award.dou + 1);
                }               
            } else if(bets[i].methodBet == MethodBet.TRIAD) {
                uint8 c = countDice(bets[i].betNumber, dices);
                if(3 == c) {
                    totalPay+= bets[i].betMoney * (award.triad + 1);
                }                
            } else if(bets[i].methodBet == MethodBet.TOTAL) {
                if(sumDice == bets[i].betNumber) {
                    totalPay+= bets[i].betMoney * (award.total[bets[i].betNumber] + 1);
                }                
            } else if(bets[i].methodBet == MethodBet.COUPLE) {
                uint8 cNum1 = countDice(bets[i].betNumber, dices);
                uint8 cNum2 = countDice(bets[i].betSecondNumber, dices);
                if(cNum1 > 0 && cNum2 > 0) {
                    totalPay+= bets[i].betMoney * (award.couple + 1);
                }                
            } else if(bets[i].methodBet == MethodBet.NUMBER) {
                uint8 c = countDice(bets[i].betNumber, dices);
                if(c > 0) {
                    c++;
                }
                totalPay+= bets[i].betMoney * (award.num * c);
            }
        }

        return totalPay;
    }

    function placeABet(Bet[] memory bets) public payable returns(GameResult memory) {
        checkRule(bets);        
        uint8 dice1 = rollDice();
        uint8 dice2 = rollDice();
        uint8 dice3 = rollDice();
        uint8[3] memory dices;
        dices[0] = dice1;
        dices[1] = dice2;
        dices[2] = dice3;
        uint256 totalPay = playerWinner(bets, dices);
        if(totalPay > 0) {
            payable(msg.sender).transfer(totalPay);
        }
        GameResult memory rs = GameResult(msg.sender, bets, dice1, dice2, dice3, totalPay);
        return rs;
    }
}
