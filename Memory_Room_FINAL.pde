/*

 Memory Room
 
 * Cris
 * Ryan
 * Yuxi
 
 OCAD University
 DIGF 6L01 Creation & Computation
 
 Created on October 28, 2012
 
 Modified on:
 * October 29, 2012
 * October 30, 2012
 * October 31, 2012
 * November 1, 2012
 
 References:
 * "Getting Joint Position in 3D Space from the Kinect" (http://learning.codasign.com/index.php?title=Getting_Joint_Position_in_3D_Space_from_the_Kinect)
 * "Reference for Simple-OpenNI and the Kinect" (http://learning.codasign.com/index.php?title=Reference_for_Simple-OpenNI_and_the_Kinect)
 * "SimpleOpenNI / Kinect: sceneMap / depthMap Color Control" (http://stackoverflow.com/questions/10433092/simpleopenni-kinect-scenemap-depthmap-color-control)
 
 */

import SimpleOpenNI.*;    // import OpenNI library

//import fullscreen.*;    // fullscreen

SimpleOpenNI  context;    // declare global context object to access camera

//boolean sketchFullScreen()    // fullscreen
{
  //return true;
}

//FullScreen fs;    // fullscreen

PFont font;    // font for on-screen info

boolean started = false;    // true = a user has entered the Kinect's view

int i = 1;    // user ID; only working with first identified user

PImage prompt;    // stores loaded image of user's still silhouette

PVector jointPos = new PVector(0, 0, 0);    // stores position of a user's joint

PVector jointPos_Proj = new PVector(0, 0, 0);    // stores, in pixels, position of a user's joint

PVector jointPosPrev = new PVector(0, 0, 0);    // stores last position of a user's joint

float vel = 0;    // stores velocity of the user's movement

float velThresh = 20;    // stores selected stillness threshold

boolean still = false;    // true = user is still

boolean onScreen = false;    // true = user is within the Kinect's view

float stillTime = 1e32;    // stores time when the user is first registered as still

float stillTime2 = 1e32;    // stores time when the user is first registered as still (backup)

int[] sceneMap;    // stores pixel values of scene map; user = 1, background = 0

PImage myUserImage;    // stores saved image of user's still silhouette

int user1Colour = color(255, 255, 255, 255);    // sets colour of user's still silhouette

boolean imagecaptured = false;    // true = user's still silhouette image has been saved

float stillDuration;    // stores how long the user stays still

PImage silh;    // stores loaded image of user's still silhouette

PImage pattern;    // stores underlying pattern for silhouette

boolean fading = false;    // true = loaded image of user's still silhouette is ready to fade to black; false = fading complete

float fadeTime;    // stores time when silhouette begins fading 

float opacity = 0;    // opacity of screen when fading to black


void setup()
{
  context = new SimpleOpenNI(this);    // instantiate new context object which communicates with the Kinect

  context.enableDepth();    // enable collection of depth data

  context.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);    // enable skeleton tracking functionality

  context.enableScene();    // enable collection of scene data

  size(context.sceneWidth(), context.sceneHeight());    // create a window same size as scene data

  sceneMap = new int[context.sceneWidth()*context.sceneHeight()];    // intialize size of sceneMap variable

  myUserImage = createImage(context.sceneWidth(), context.sceneHeight(), RGB);    // initialize size/style of myUserImage variable

  fill(0);    // set fill to black

  stroke(0);    // set stroke to black

  font = createFont("Arial", 12, true);    // font: Arial, 16pt, with anti-aliasing

  textFont(font);    // use this font throughout the program

  noCursor();    // hide cursor while sketch is running

  //  fs = new FullScreen(this);    // fullscreen

  //  fs.enter();    // fullscreen

  prompt = loadImage("prompt.jpg");    // load pose prompt image

    image(prompt, 0, 0, width, height);    // display pose prompt image

  pattern = loadImage("pattern.jpg");    // load underlying pattern for silhouette
}


void draw()
{
  context.update();    // the context is updated with camera information

  if (context.isTrackingSkeleton(i)&&(fading == false))    // if the skeleton is being tracked
  {
    getJoint(i);    // get coordinates of user's joint

    if ((jointPos_Proj.x > 80)&&(jointPos_Proj.x < (width - 80)))    // if user is well on screen
    {
      onScreen = true;
    }
    else    // if user is not well on screen
    {
      onScreen = false;
    }

    if (onScreen == true)
    {
      vel = PVector.dist(jointPos, jointPosPrev);    // measure joint velocity

      if (vel > velThresh)     // if user is moving
      {
        stillTime = 1e32;    // reset stillTime

        still = false;    // current state: not still

        fill(0);
        text("User is still", 30, 30);    // remove stillness indicator text
      }

      if ((vel < velThresh)&&(still == false))    // if user is still for the first time
      {
        stillTime = millis();    // record current time

        still = true;    // current state: still

        fill(255);
        text("User is still", 30, 30);    // display stillness indicator text
        fill(0);
      }

      if ((millis() > (stillTime + 3000))&&(vel < velThresh)&&(still == true)&&(imagecaptured == false))    // if user has remained still for 3 seconds
      {
        stillTime2 = stillTime + 1000;    // backup stillTime value

        context.sceneMap(sceneMap);    // update the scene map

          Arrays.fill(myUserImage.pixels, color(0));    // fill myUserImage with zeros

        for (int j = 0 ; j < myUserImage.pixels.length; j++)    // for each pixel of myUserImage
        {
          if (sceneMap[j] > 0) myUserImage.pixels[j] = user1Colour;    // colour any pixel occupied by user
        }

        myUserImage.updatePixels();    // update myUserImage with new pixel values

          image(myUserImage, 0, 0);    // display myUserImage

        save("silhouette.jpg");    // capture screenshot

        background(0, 0, 0);    // blacken screen

        imagecaptured = true;    // current state: image has been captured

        fill(255);
        text("User image captured", 30, 30);    // display image capture indicator text
        fill(0);

        println("User became still at " + stillTime2/1000 + " seconds");
      }

      if ((imagecaptured == true)&&(still == false))    // if image has been captured and user begins to move
      {
        stillDuration = millis() - stillTime2;    // record time user stayed still

        println("User remained still for " + stillDuration/1000 + " seconds");

        silh = loadImage("silhouette.jpg");    // load captured image

          pattern.resize(silh.width, silh.height);    // match size of pattern to that of mask

        pattern.mask(silh);    // mask silhouette over pattern

        imagecaptured = false;    // current state: captured image successfully loaded; reset

        fading = true;    // current state: image is ready for fading

        fadeTime = millis();    // record time when silhouette begins fading
      }

      jointPosPrev = jointPos.get();    // store previous joinPos value
    }
  }

  if (fading == true)    // if image is ready for fading
  { 
    if (opacity <= 255)    // if opacity is not maxed
    {
      image(pattern, 0, 0, width, height);    // display silhouette with underlying pattern

      opacity = map(millis(), fadeTime, (fadeTime + stillDuration), 0, 255);    // increase opacity

      fill(0, opacity);    // update fill

      rect(0, 0, width, height);    // draw filled rectangle
    }
    else if (opacity > 255)    // if opacity is maxed
    {
      fading = false;    // current state: fading complete

        opacity = 0;    // reset opacity

      fill(0, opacity);    // update fill
    }
  }
}


void getJoint(int userID)    // function: retrieve 3D coordinates of selected joint
{
  context.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_HEAD, jointPos);    // request join position of the torso

  context.convertRealWorldToProjective(jointPos, jointPos_Proj);    // convert real world point to projective space
}

void onNewUser(int userId)    // function: when a user enters the field of view
{
  println("User detected!");

  while (fading)    // wait until fading of last silhouette has stopped
  {
  }

  image(prompt, 0, 0, width, height);    // display pose prompt image

  context.startPoseDetection("Psi", 1);    // start pose detection
}

void onLostUser(int userId)    // function: when a user leaves the field of view
{
  println("User lost!");
}

void onStartPose(String pose, int userId)    // function: when a user begins a pose
{
  println("Start of pose detected!");

  context.stopPoseDetection(1);    // stop pose detection

  context.requestCalibrationSkeleton(1, true);    // start attempting to calibrate the skeleton
}

void onStartCalibration(int userId)    // function: when calibration begins
{
  println("Beginning calibration!");
}

void onEndCalibration(int userId, boolean successfull)    // function: when calibaration ends - successfully or unsucessfully
{
  print("Calibration of user ");

  if (successfull) 
  { 
    println("sucessful!");

    background(0, 0, 0);    // blacken screen

    context.startTrackingSkeleton(1);    // begin skeleton tracking
  } 
  else 
  {
    println("failed!");

    context.startPoseDetection("Psi", 1);    // start pose detection
  }
}

