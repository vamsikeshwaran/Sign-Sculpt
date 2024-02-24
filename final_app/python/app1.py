import cv2
import mediapipe as mp
import urllib.request
from firebase_admin import credentials, initialize_app, storage
from flask import Flask, request, jsonify

app = Flask(__name__)

cred = credentials.Certificate(
    "D:/final/final_app/app/asset/serviceAcc.json")
initialize_app(cred, {"storageBucket": "htmlapp-fa3bc.appspot.com"})
bucket = storage.bucket()

mp_holistic = mp.solutions.holistic
mp_drawing = mp.solutions.drawing_utils


def upload_video_to_firebase(video_path, destination_path):
    try:
        blob = bucket.blob(destination_path)
        blob.upload_from_filename(video_path)
        print(f"Video uploaded to {blob.public_url}")
    except Exception as e:
        print(f"Error uploading video - {e}")


def download_http_video(url, destination):
    try:
        with urllib.request.urlopen(url) as response, open(destination, 'wb') as out_file:
            out_file.write(response.read())
        print(f"Download successful. Content saved to {destination}")
    except Exception as e:
        print(f"Error: {e}")


def draw_styled_landmarks(image, results):
    if results.pose_landmarks:
        mp_drawing.draw_landmarks(image, results.pose_landmarks, mp_holistic.POSE_CONNECTIONS,
                                  landmark_drawing_spec=mp_drawing.DrawingSpec(color=(80, 22, 10), thickness=2,
                                                                               circle_radius=4),
                                  connection_drawing_spec=mp_drawing.DrawingSpec(color=(80, 44, 121), thickness=2,
                                                                                 circle_radius=2))

    if results.left_hand_landmarks:
        mp_drawing.draw_landmarks(image, results.left_hand_landmarks, mp_holistic.HAND_CONNECTIONS,
                                  landmark_drawing_spec=mp_drawing.DrawingSpec(color=(121, 22, 76), thickness=2,
                                                                               circle_radius=4),
                                  connection_drawing_spec=mp_drawing.DrawingSpec(color=(121, 44, 250), thickness=2,
                                                                                 circle_radius=2))

    if results.right_hand_landmarks:
        mp_drawing.draw_landmarks(image, results.right_hand_landmarks, mp_holistic.HAND_CONNECTIONS,
                                  landmark_drawing_spec=mp_drawing.DrawingSpec(color=(245, 117, 66), thickness=2,
                                                                               circle_radius=4),
                                  connection_drawing_spec=mp_drawing.DrawingSpec(color=(245, 66, 230), thickness=2,
                                                                                 circle_radius=2))


@app.route('/chat', methods=['GET'])
def chatbot():
    url_to_download = "https://firebasestorage.googleapis.com/v0/b/sign-app-d3980.appspot.com/o/videos%2Fsample.mp4?alt=media&token=387c08bb-4f0a-4653-af15-832c14f66844"
    destination_file = "sample_video.mp4"
    download_http_video(url_to_download, destination_file)

    video_path = "D:/final/final_app/app/asset/sample_video.mp4"
    output_video_path = "D:/final/final_app/app/asset/output_video.mp4"

    cap = cv2.VideoCapture(video_path)

    if not cap.isOpened():
        return jsonify({"message": "Error: Couldn't open video file."}), 500

    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    fourcc = cv2.VideoWriter_fourcc(*'X264')  
    out = cv2.VideoWriter(output_video_path, fourcc, 20.0, (width, height))

    with mp_holistic.Holistic(min_detection_confidence=0.5, min_tracking_confidence=0.5) as holistic:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = holistic.process(frame_rgb)
            draw_styled_landmarks(frame, results)
            frame_bgr = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
            out.write(frame_bgr)

    cap.release()
    out.release()

    firebase_destination_path = "video.mp4"
    upload_video_to_firebase(output_video_path, firebase_destination_path)

    return jsonify({"message": "Success"}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)