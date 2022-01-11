# THE MASK : IMS _ V3
import cv2
from mtcnn_cv2 import MTCNN
import time
import numpy as np
import argparse
import time
from pythonosc import udp_client

#DEFS
counter = 0
stime = time.time()
#face
face_detector = MTCNN()
color0 = (0, 255, 0)
color1 = (0, 155, 255)
color2 = (0, 255, 255)
line_thickness = 1
#
font = cv2.FONT_HERSHEY_SIMPLEX
fontScale = 1
color = (255, 0, 0)
thickness = 2
org = (50, 50)
#
frameWidth = 640
frameHeight = 480
fps = 1000
trigger_iter = 30 # record and play 1 minutes - after mentioned times blanks iter
"""make trigger iter dynamic"""


# FUNC DEF
def detectPlay(frame):
    facer = face_detector.detect_faces(frame) #Detector
    if facer == []:
        print('rec')
        global counter
        counter += 1
    else:
        counter = 0
    if counter == trigger_iter:
        global session_timeS
        session_timeS = 0

    for fac in facer:
        if fac.__getitem__('confidence') >= 0.7:
            keypoints = fac.__getitem__('keypoints')
            bounding_box = fac.__getitem__('box')
            A = (bounding_box[0], bounding_box[1])
            B = (bounding_box[0] + bounding_box[2], bounding_box[1])
            C = (bounding_box[0] + bounding_box[2], bounding_box[1] + bounding_box[3])
            D = (bounding_box[0], bounding_box[1] + bounding_box[3])
            #"""
            #play OSC parameters#
            valFreq = np.average(keypoints.__getitem__('nose'))
            valRoom = keypoints.__getitem__('left_eye')[0]
            valRevt = keypoints.__getitem__('right_eye')[0]
            valAmp = bounding_box[3]
            valDcy = bounding_box[1]
            valPhs = bounding_box[0]
            valRate = keypoints.__getitem__('mouth_right')[0]
            valSpr = max(keypoints.__getitem__('nose'))
            valPr = keypoints.__getitem__('mouth_left')[0]
            valPan = B[0]
            valDly = 1 - fac.__getitem__('confidence')
            eyeAxis = keypoints.__getitem__('left_eye')[1] - keypoints.__getitem__('right_eye')[1]
            mouthAxis = keypoints.__getitem__('mouth_left')[1] - keypoints.__getitem__('mouth_right')[1]
            #
            osc_msg = ['M', valFreq , valRoom, valRevt, valAmp, valDcy, valPhs,
                       valRate, valSpr, valPr, valPan, valDly, eyeAxis, mouthAxis]
            client.send_message("/pyOsc", osc_msg)  # manipulate
            print(osc_msg)
            #"""
            cv2.rectangle(frame, A, C, color0, line_thickness + 1)
    cv2.imshow('Capture - Face detection', frame)
    #print(counter)



#PLAY
#osc
ccnt = 0
session_timeS = time.time()
if __name__ == "__main__":
  parser = argparse.ArgumentParser()
  parser.add_argument("--ip", default="127.0.0.1",
      help="The ip of the OSC server")
  parser.add_argument("--port", type=int, default=57121,
      help="The port the OSC server is listening on")
  args = parser.parse_args()
  client = udp_client.SimpleUDPClient(args.ip, args.port)
  #
  cap = cv2.VideoCapture(0)
  cap.set(3, frameWidth)
  cap.set(4, frameHeight)
  cap.set(5, fps)
  #
  if not cap.isOpened:
      print('--Error opening video capture')
      client.send_message("/pyOsc", ['S'])  # stop
      exit(0)
  while True:
      ret, frame = cap.read()
      if frame is None or cv2.waitKey(1) == 27:
          print('--No captured frame! OR --waitKey Error!')
          client.send_message("/pyOsc", ['S'])  # stop
          break
      detectPlay(frame)
      time.sleep(60 / fps)
      session_time = time.time() - session_timeS
      if session_time >= 52:
          client.send_message("/pyOsc", ['S'])  # stop
          client.send_message("/pyOsc", ['R'])  # record
          print('Recording')
          time.sleep(8)
          client.send_message("/pyOsc", ['P'])  # play
          print('Perform!')
          session_timeS = time.time()
      print(str(ccnt) + ":" + str(session_time))
      ccnt += 1
print('END')