/////////////////////////////////////////////////////////////////////////////////////////
//
// COMS20001
// ASSIGNMENT 1
// CODE SKELETON
// TITLE: "LED Ant Defender Game"
//
/////////////////////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <platform.h>

out port cled0 = PORT_CLOCKLED_0;
out port cled1 = PORT_CLOCKLED_1;
out port cled2 = PORT_CLOCKLED_2;
out port cled3 = PORT_CLOCKLED_3;
out port cledG = PORT_CLOCKLED_SELG;
out port cledR = PORT_CLOCKLED_SELR;
in port  buttons = PORT_BUTTON;
out port speaker = PORT_SPEAKER;

/////////////////////////////////////////////////////////////////////////////////////////
//
//  Helper Functions provided for you
//
/////////////////////////////////////////////////////////////////////////////////////////

//DISPLAYS an LED pattern in one quadrant of the clock LEDs
int showLED(out port p, chanend fromVisualiser) {
  unsigned int lightUpPattern;
  while (1) {
    fromVisualiser :> lightUpPattern; //read LED pattern from visualiser process
    p <: lightUpPattern;              //send pattern to LEDs
  }
  return 0;
}

//PROCESS TO COORDINATE DISPLAY of LED Ants
void visualiser(chanend fromUserAnt, chanend fromAttackerAnt, chanend toQuadrant0, chanend toQuadrant1, chanend toQuadrant2, chanend toQuadrant3) {
  unsigned int userAntToDisplay = 11;
  unsigned int attackerAntToDisplay = 5;
  int i, j;
  cledR <: 1;
  while (1) {
    select {
      case fromUserAnt :> userAntToDisplay:
        break;
      case fromAttackerAnt :> attackerAntToDisplay:
        break;
    }
    j = 16<<(userAntToDisplay%3);
    i = 16<<(attackerAntToDisplay%3);
    toQuadrant0 <: (j*(userAntToDisplay/3==0)) + (i*(attackerAntToDisplay/3==0)) ;
    toQuadrant1 <: (j*(userAntToDisplay/3==1)) + (i*(attackerAntToDisplay/3==1)) ;
    toQuadrant2 <: (j*(userAntToDisplay/3==2)) + (i*(attackerAntToDisplay/3==2)) ;
    toQuadrant3 <: (j*(userAntToDisplay/3==3)) + (i*(attackerAntToDisplay/3==3)) ;
  }
}

//PLAYS a short sound (pls use with caution and consideration to other students in the labs!)
void playSound(unsigned int wavelength, out port speaker) {
  timer  tmr;
  int t, isOn = 1;
  tmr :> t;
  for (int i=0; i<2; i++) {
    isOn = !isOn;
    t += wavelength;
    tmr when timerafter(t) :> void;
    speaker <: isOn;
  }
}

//READ BUTTONS and send to userAnt
void buttonListener(in port b, out port spkr, chanend toUserAnt) {
  int r;
  while (1) {
    b when pinsneq(15) :> r;   // check if some buttons are pressed
    playSound(2000000,spkr);   // play sound
    toUserAnt <: r;            // send button pattern to userAnt
  }
}


//WAIT function
void waitMoment() {
  timer tmr;
  uint waitTime;
  tmr :> waitTime;
  waitTime += 10000000;
  tmr when timerafter(waitTime) :> void;
}

int mod(int a, int b) {
    return (a % b + b) % b;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
//  MOST RELEVANT PART OF CODE TO EXPAND FOR YOU
//
/////////////////////////////////////////////////////////////////////////////////////////

//DEFENDER PROCESS... The defender is controlled by this process userAnt,
//                    which has channels to a buttonListener, visualiser and controller
void userAnt(chanend fromButtons, chanend toVisualiser, chanend toController) {
  int userAntPosition = 11;       //the current defender position
  int buttonInput;                         //the input pattern from the buttonListener
  int attemptedAntPosition = 0;   //the next attempted defender position after considering button
  int moveForbidden;                       //the verdict of the controller if move is allowed
  int gameIsOver = 0;
  toVisualiser <: userAntPosition;         //show initial position

  while (!gameIsOver) {  fromButtons :> buttonInput;
    if (buttonInput == 14) attemptedAntPosition = mod((userAntPosition + 1), 12);
    if (buttonInput == 7)  attemptedAntPosition = mod((userAntPosition - 1), 12);

    printf("Attempted ant position: %d\n", attemptedAntPosition);

    toController <: attemptedAntPosition;
    toController :> moveForbidden;

    if (moveForbidden == 0) {
        userAntPosition = attemptedAntPosition;
        toVisualiser <: userAntPosition;
    } else if (moveForbidden == 2) {
        gameIsOver = 1;
    }

  }
}

//ATTACKER PROCESS... The attacker is controlled by this process attackerAnt,
//                    which has channels to the visualiser and controller
void attackerAnt(chanend toVisualiser, chanend toController) {
  int moveCounter = 0;                       //moves of attacker so far
  unsigned int attackerAntPosition = 5;      //the current attacker position
  unsigned int attemptedAntPosition;         //the next attempted  position after considering move direction
  int currentDirection = 1;                  //the current direction the attacker is moving
  int moveForbidden = 0;                     //the verdict of the controller if move is allowed
  int gameIsOver = 0;
  toVisualiser <: attackerAntPosition;       //show initial position

  while (!gameIsOver) {

      if (moveCounter % 31 == 0 || moveCounter % 37 == 0 || moveCounter % 47 == 0) {
          currentDirection *= -1;
      }

      attemptedAntPosition = mod((attackerAntPosition + currentDirection), 12);


      toController <: attemptedAntPosition;
      toController :> moveForbidden;

      if (moveForbidden == 0) {
          attackerAntPosition = attemptedAntPosition;
          toVisualiser <: attackerAntPosition;
          moveCounter += 1;
      } else if (moveForbidden == 1){
          currentDirection *= -1;
      } else {
          gameIsOver = 1;
      }

      waitMoment();
  }
}

//COLLISION DETECTOR... the controller process responds to �permission-to-move� requests
//                      from attackerAnt and userAnt. The process also checks if an attackerAnt
//                      has moved to LED positions I, XII and XI.
void controller(chanend fromAttacker, chanend fromUser) {
  unsigned int lastReportedUserAntPosition = 11;      //position last reported by userAnt
  unsigned int lastReportedAttackerAntPosition = 5;   //position last reported by attackerAnt
  unsigned int attempt = 0;
  int gameIsOver = 0;
  fromUser :> attempt;                                //start game when user moves
  fromUser <: 1;                                      //forbid first move

  while (!gameIsOver) {
    select {
      case fromAttacker :> attempt:
          if (attempt == lastReportedUserAntPosition) {
              fromAttacker <: 1;
          } else {
              if (lastReportedAttackerAntPosition == 0 || lastReportedAttackerAntPosition == 11 || lastReportedAttackerAntPosition == 10) {
                  fromAttacker <: 2;
                  fromUser <: 2;
                  gameIsOver = 1;
              } else {
                  lastReportedAttackerAntPosition = attempt;
                  fromAttacker <: 0;
              }
          }
        break;
      case fromUser :> attempt:
          if (attempt == lastReportedAttackerAntPosition) {
              fromUser <: 1;
          } else {
              lastReportedUserAntPosition = attempt;
              fromUser <: 0;
          }
          break;
    }
  }
}

//MAIN PROCESS defining channels, orchestrating and starting the processes
int main(void) {
  chan buttonsToUserAnt,         //channel from buttonListener to userAnt
       userAntToVisualiser,      //channel from userAnt to Visualiser
       attackerAntToVisualiser,  //channel from attackerAnt to Visualiser
       attackerAntToController,  //channel from attackerAnt to Controller
       userAntToController;      //channel from userAnt to Controller
  chan quadrant0,quadrant1,quadrant2,quadrant3; //helper channels for LED visualisation

  par {
    //PROCESSES FOR YOU TO EXPAND
    on stdcore[1]: userAnt(buttonsToUserAnt,userAntToVisualiser,userAntToController);
    on stdcore[2]: attackerAnt(attackerAntToVisualiser,attackerAntToController);
    on stdcore[3]: controller(attackerAntToController, userAntToController);

    //HELPER PROCESSES
    on stdcore[0]: buttonListener(buttons, speaker,buttonsToUserAnt);
    on stdcore[0]: visualiser(userAntToVisualiser,attackerAntToVisualiser,quadrant0,quadrant1,quadrant2,quadrant3);
    on stdcore[0]: showLED(cled0,quadrant0);
    on stdcore[1]: showLED(cled1,quadrant1);
    on stdcore[2]: showLED(cled2,quadrant2);
    on stdcore[3]: showLED(cled3,quadrant3);
  }
  return 0;
}