import netP5.*;
import oscP5.*;

import damkjer.ocd.*;
import shapes3d.*;

PImage WALL_TEXTURE;
PImage GROUND_TEXTURE;
PImage TRAP_TEXTURE;
PImage OBST_TEXTURE;
PImage GOAL_TEXTURE;
PImage SKY_TEXTURE;
PImage GAME_OVER;
PImage FINISH;

Camera camera;
char[][] map;
int life = 300; // game over after 600 frames on trap
boolean finish = false;

float CASE_SIZE = 10; // size of a unit on maze
float cam_x = 15; // starting x position
float cam_y = -5; // camera's eye level
float cam_z = 15; // starting z position

Box wall;
Ellipsoid sky;

boolean blood = true;
boolean gameOver = false;

OscP5 oscP5;
NetAddress mobile;

void setup() {
  size(1000, 600, P3D);
  oscP5 = new OscP5(this, 12000);
  //mobile = new NetAddress("10.1.178.132", 12000);
  mobile = new NetAddress("127.0.0.1",12000);
  noStroke();
  // camera setup
  camera = new Camera(this, cam_x, cam_y, cam_z, 0.03, 500);

  // load texture image
  WALL_TEXTURE = loadImage("brick.jpg");
  GROUND_TEXTURE = loadImage("concrete.jpg");
  TRAP_TEXTURE = loadImage("trap.jpg");
  GOAL_TEXTURE = loadImage("goal.png");
  SKY_TEXTURE = loadImage("sky.jpg");
  GAME_OVER = loadImage("gameover.png");
  FINISH = loadImage("finish.png");

  // get map information from the map.txt
  String[] lines = loadStrings("map.txt");
  map = new char[lines.length][lines[0].length()];
  for (int row = 0; row < lines.length; row++) {
    for (int col = 0; col < lines[row].length(); col++) {
      map[row][col] = lines[row].charAt(col);
    }
  }

  wall = new Box(this, CASE_SIZE); // box
  wall.drawMode(S3D.TEXTURE);
  wall.setTexture(WALL_TEXTURE);

  sky = new Ellipsoid(this, 20, 30);
  sky.setTexture(SKY_TEXTURE);
  sky.drawMode(Shape3D.TEXTURE);
  sky.setRadius(300);
}

void draw() {

  background(#adccff);
  fill(255);

  translate(width / 2, height / 2, 0);
  ambientLight(4, 4, 4);
  //directionalLight(255, 255, 255, 0, 0, 0);
  camera.feed(); // send what this camera sees to the view port
  /*
  spotLight(255, 255, 255, 
   camera.position()[0], camera.position()[1], camera.position()[2],
   camera.attitude()[0], camera.attitude()[1], camera.attitude()[2],
   PI/2,
   2
   );
   */
  pushMatrix();
  translate(camera.position()[0], camera.position()[1], camera.position()[2]);
  PVector target = new PVector(camera.target()[0], camera.target()[1], camera.target()[2]);
  PVector camera_position = new PVector(camera.position()[0], camera.position()[1], camera.position()[2]);
  PVector direction = target.sub(camera_position).normalize();
  lightFalloff(0.5, 0.001, 0.01);
  spotLight(255, 255, 255, 0, 0, 0, direction.x, direction.y, direction.z, PI/2, 2);
  popMatrix();
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
      case '-':
        drawGround();
        break;
      case '~':
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

  // camera moving
  if (keyPressed && key != CODED) {
    float[] pos = camera.position(); 
    switch (key) {
    case 'w':
    case 's':
      float[] original_target = camera.target();
      float[] original_camera = camera.position();
      camera.dolly(key=='w'?-0.5:0.5); // move the camera along the view vector by the parameter(distance)
      float[] pos1 = camera.position();
      camera.jump(pos1[0], cam_y, pos1[2]); // instantly change the camera's position to the parameter(location)
      float[] changed_camera = camera.position();
      changed_camera[0]-=original_camera[0];
      changed_camera[1]-=original_camera[1];
      changed_camera[2]-=original_camera[2];
      original_target[0]+=changed_camera[0];
      original_target[1]+=changed_camera[1];
      original_target[2]+=changed_camera[2];
      camera.aim(original_target[0], original_target[1], original_target[2]);
      break;
    case 'a':
      camera.truck(-0.5); // move the camera along the side vector by the parameter(distance)
      break;
    case 'd':
      camera.truck(0.5); // move the camera along the side vector by the parameter(distance)
      break;
    }

    // not allowed to cross the trap or obstacle
    if (!WalkAcross(camera)) {
      camera.jump(pos[0], cam_y, pos[2]); // reset the camera position
    }
  }

  trapCheck(camera);
  goalCheck(camera);

  OscMessage coordsMessage = new OscMessage("/coords");
  coordsMessage.add(camera.position()[0]);
  coordsMessage.add(camera.position()[1]);
  coordsMessage.add(camera.position()[2]);
  oscP5.send(coordsMessage, mobile);

  Camera camera1 = new Camera(this, width/2.0, height/2.0, (height/2.0) / tan(PI*30.0 / 180.0), width/2.0, height/2.0, 0, 0, 1, 0);
  camera1.feed();

  ambientLight(255, 255, 255);
  if (life < 0) {
    fill(0);
    imageMode(CENTER);
    background(255);
    image(GAME_OVER, width/2, height/2);
  } else if (finish) {
    fill(0);
    imageMode(CENTER);
    background(255);
    image(FINISH, width/2, height/2);
  } else { 
    if (blood) {
      fill(255, 0, 0, 100);
    } else {
      fill(255, 255, 255, 0);
    }
    rect(0, 0, width, height);
    fill(255, 0, 0, 255);
    rect(0, 0, map(life, 0, 300, 0, width), 40);
  }
}

void mouseMoved() {
  camera.look(radians(mouseX - pmouseX) / 5.0, radians(mouseY - pmouseY) / 5.0); // move the camera's view at its current position by the parameter(amounts)
}

void drawWall() {
  pushMatrix();
  translate(CASE_SIZE / 2, -CASE_SIZE / 2, CASE_SIZE / 2);
  wall.draw();
  popMatrix();
  noFill();
}

void drawGround() {
  beginShape(QUADS);
  texture(GROUND_TEXTURE);
  vertex(0, 0, 0, 0, 0);
  vertex(CASE_SIZE, 0, 0, 1, 0);
  vertex(CASE_SIZE, 0, CASE_SIZE, 1, 1);
  vertex(0, 0, CASE_SIZE, 0, 1);
  endShape();
  noFill();
}

void drawTrap() {
  beginShape(QUADS);
  texture(TRAP_TEXTURE);
  vertex(0, 0, 0, 0, 0);
  vertex(CASE_SIZE, 0, 0, 1, 0);
  vertex(CASE_SIZE, 0, CASE_SIZE, 1, 1);
  vertex(0, 0, CASE_SIZE, 0, 1);
  endShape();
  noFill();
}

void drawGoal() {
  beginShape(QUADS);
  texture(GOAL_TEXTURE);
  vertex(0, 0, 0, 0, 0);
  vertex(CASE_SIZE, 0, 0, 1, 0);
  vertex(CASE_SIZE, 0, CASE_SIZE, 1, 1);
  vertex(0, 0, CASE_SIZE, 0, 1);
  endShape();
  noFill();
}

void drawSky() {  
  sky.draw();
}

// return true if the camera is able to walk across the unit, false if is not.
boolean WalkAcross(Camera camera) {
  char unitContent = unitContent(camera);
  if (unitContent == '-') {
    int[] unitIds = currentUnit(camera);
    map[unitIds[0]][unitIds[1]] = '~';
  }
  return unitContent == ' ' || unitContent == '~' || unitContent == '-' || unitContent == '$';
}

// check if the camera is on trap
void trapCheck(Camera camera) {
  char unitContent = unitContent(camera);
  if (unitContent == '~' || unitContent == '-') {
    blood = true;
    life--;
    println(life);
  } else {
    fill(255);
    blood = false;
  }
}

// check if the camera found the goal
void goalCheck(Camera camera) {
  char unitContent = unitContent(camera);
  if (unitContent == '$') {
    finish = true;
  } else {
    finish = false;
  }
}

// return char of content of the current case of the map
char unitContent(Camera camera) {
  int[] unitIds = currentUnit(camera);
  return map[unitIds[0]][unitIds[1]];
}

// return row,col array which is camera's current position
int[] currentUnit(Camera camera) {
  float[] position = camera.position();

  return new int[]{
    (int) (position[2] / CASE_SIZE), 
    (int) (position[0] / CASE_SIZE) };
}