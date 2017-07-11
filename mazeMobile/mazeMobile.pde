import netP5.*;
import oscP5.*;
import damkjer.ocd.*;

PImage WALL_TEXTURE;
PImage GROUND_TEXTURE;
PImage TRAP_TEXTURE;
PImage OBST_TEXTURE;
PImage SKY_TEXTURE;
PImage PLAYER_TEXTURE;
PImage GOAL_TEXTURE;
PImage GAME_OVER;

Camera camera;
char[][] map;
int life = 300; // game over after 600 frames on trap

float CASE_SIZE = 10; // size of a unit on maze
float cam_x = 15; // starting x position
float cam_y = -5; // camera's eye level
float cam_z = 15; // starting z position

PVector player_xyz = new PVector(-1000, -1000, -1000);

OscP5 oscP5;

void setup() {
  size(200, 160, P3D);
  noStroke();

  oscP5 = new OscP5(this, 12000);

  // camera setup
  camera = new Camera(this, 60, -140, 60, 0.03, 400);
  camera.aim(60, 0, 59);

  // load texture image
  WALL_TEXTURE = loadImage("brick.jpg");
  GROUND_TEXTURE = loadImage("concrete.jpg");
  TRAP_TEXTURE = loadImage("trap.jpg");
  SKY_TEXTURE = loadImage("desertSkybox.jpg");
  GAME_OVER = loadImage("gameover.png");
  GOAL_TEXTURE = loadImage("goal.png");
  PLAYER_TEXTURE = loadImage("github-icon.png");

  // get map information from the map.txt
  String[] lines = loadStrings("map.txt");
  map = new char[lines.length][lines[0].length()];
  for (int row = 0; row < lines.length; row++) {
    for (int col = 0; col < lines[row].length(); col++) {
      map[row][col] = lines[row].charAt(col);
    }
  }
}

void draw() {
  background(#adccff);
  translate(width / 2, height / 2, 0);
  ambientLight(200, 200, 200);
  directionalLight(255, 255, 255, 0, 0, 0);
  camera.feed(); // send what this camera sees to the view port
  drawSky(); // draw a sky

  // draw map
  for (int row = 0; row < map.length; row++) {
    pushMatrix();
    translate(0, 0, row * CASE_SIZE);

    for (int col = 0; col < map[row].length; col++) {
      pushMatrix();
      translate(col * CASE_SIZE, 0, 0);

      switch (map[row][col]) {
      case '#':
        drawWall();
        break;
      case '~':
      case '-':
        drawTrap();
        break;
      case '$':
        drawGoal();
        break;
      default:
        drawGround();
      }
      popMatrix();
    }
    popMatrix();
  }
  
  pushMatrix();
  translate(player_xyz.x, player_xyz.y, player_xyz.z);
  drawPlayer();
  popMatrix();

  //trapCheck();
  if (life < 0) {
    fill(0);
    // not shown
    imageMode(CENTER);
    image(GAME_OVER, width /2, height / 2);
  }
}

void drawWall() {
  beginShape(QUADS);
  texture(WALL_TEXTURE);
  vertex(0, 0, 0, 0, 0);
  vertex(CASE_SIZE, 0, 0, 2560, 0);
  vertex(CASE_SIZE, 0, CASE_SIZE, 2560, 1920);
  vertex(0, 0, CASE_SIZE, 0, 1920);
  endShape();
  noFill();
}

void drawPlayer() {
  pushMatrix();
  translate(-CASE_SIZE/2, 0, -CASE_SIZE/2);
  beginShape(QUADS);
  texture(PLAYER_TEXTURE);
  vertex(0, 0, 0, 0, 0);
  vertex(CASE_SIZE, 0, 0, 256, 0);
  vertex(CASE_SIZE, 0, CASE_SIZE, 256, 256);
  vertex(0, 0, CASE_SIZE, 0, 256);
  endShape();
  noFill();
  popMatrix();
}

void drawGround() {
  beginShape(QUADS);
  texture(GROUND_TEXTURE);
  vertex(0, 0, 0, 0, 0);
  vertex(CASE_SIZE, 0, 0, 500, 0);
  vertex(CASE_SIZE, 0, CASE_SIZE, 500, 300);
  vertex(0, 0, CASE_SIZE, 0, 300);
  endShape();
  noFill();
}

void drawTrap() {
  beginShape(QUADS);
  texture(TRAP_TEXTURE);
  vertex(0, 0, 0, 0, 0);
  vertex(CASE_SIZE, 0, 0, 400, 0);
  vertex(CASE_SIZE, 0, CASE_SIZE, 400, 400);
  vertex(0, 0, CASE_SIZE, 0, 400);
  endShape();
  noFill();
}

void drawGoal(){
  beginShape(QUADS);
  texture(GOAL_TEXTURE);
  vertex(0, 0, 0, 0, 0);
  vertex(CASE_SIZE, 0, 0, 800, 0);
  vertex(CASE_SIZE, 0, CASE_SIZE, 800, 800);
  vertex(0, 0, CASE_SIZE, 0, 800);
  endShape();
  noFill();
}

void drawSky() {  
  //sky.draw();
}

// return true if the camera is able to walk across the unit, false if is not.
boolean WalkAcross(PVector position) {
  char unitContent = unitContent(position);
  return unitContent == ' ' || unitContent == '~';
}

// check if the camera is on trap
void trapCheck(PVector position) {
  char unitContent = unitContent(position);
  if (unitContent == '~') {
    fill(255, 0, 0, 0.7);
    rect(0, 0, width, height);
    life--;
    println(life);
  } else {
    fill(255);
  }
}

// return char of content of the current case of the map
char unitContent(PVector position) {
  int[] unitIds = currentUnit(position);
  return map[unitIds[0]][unitIds[1]];
}

// return row,col array which is camera's current position
int[] currentUnit(PVector position) {
  return new int[]{
    (int) (position.z / CASE_SIZE), 
    (int) (position.x / CASE_SIZE) };
}

void oscEvent(OscMessage theOscMessage) {
  /* get and print the address pattern and the typetag of the received OscMessage */
  println("### received an osc message with addrpattern "+theOscMessage.addrPattern()+" and typetag "+theOscMessage.typetag());
  player_xyz = new PVector(theOscMessage.get(0).floatValue(), theOscMessage.get(1).floatValue(), theOscMessage.get(2).floatValue());
}