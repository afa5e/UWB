<<<<<<< Updated upstream
=======
import net.java.games.input.*;
import org.gamecontrolplus.*;
import org.gamecontrolplus.gui.*;
import g4p_controls.*;
ControlDevice cont;
ControlIO control;
Rover rover = new Rover(150, 825);

void setup() {
  size(983,906);
  frameRate(60);

  PImage img;
  img = loadImage("bg.png");
  background(img);

  fill(0,0,255);
  ellipse(150, 825, 80, 80);
}

void draw() {

}

class Rover {
  float xpos, ypos;
  Rover (float x, float y) {
    xpos = x;
    ypos = y;
  }
  void update(float xvel, float yvel) {
    xpos = xpos + xvel;
    ypos = ypos + yvel;
    PImage img;
    img = loadImage("bg.png");
    background(img);
    fill(0,0,255);
    ellipse(xpos, ypos, 80, 80);
  }
}

void keyPressed() {
  float x, y;

  x = 0;
  y = 0;

  if (key == 'w') {
    y = -10;
  } else if (key == 's') {
    y = 10;
  } else if (key == 'a') {
    x = -10;
  } else if (key == 'd') {
    x = 10;
  } else if (key == 'q') {
    println("lowering");
  } else if (key == 'e') {
    println("raising");
  } else if (key == 'r') {
    println("Opening rear door");
  } else if (key == 'f') {
    println("closing rear door");
  } else {
    println("invalid");
  }

  rover.update(x, y);
}
