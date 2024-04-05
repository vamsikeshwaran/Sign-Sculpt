from flask import Flask, request, jsonify
from threading import Thread
import time
import urllib.request
import cv2
import mediapipe as mp
import numpy as np
import google.generativeai as genai
import google.ai.generativelanguage as glm
from dotenv import load_dotenv
import os
from tensorflow.keras.models import load_model
from moviepy.editor import VideoFileClip, concatenate_videoclips
import tempfile
from firebase_admin import credentials, initialize_app, storage


app = Flask(__name__)

cred = credentials.Certificate(
    "D:/final/final_app/python/serviceAcc.json")
initialize_app(cred, {"storageBucket": "htmlapp-fa3bc.appspot.com"})
bucket = storage.bucket()
mp_holistic = mp.solutions.holistic
mp_drawing = mp.solutions.drawing_utils
model = None
actions = None

actions = np.array(['hello', 'thankyou'])


def upload_video_to_firebase(video_path, destination_path):
    try:
        blob = bucket.blob(destination_path)
        blob.upload_from_filename(video_path)
        print(f"Video uploaded to {blob.public_url}")
    except Exception as e:
        print(f"Error uploading video - {e}")


def load_model_and_actions():
    global model
    model = load_model('D:/final/final_app/python/action.h5')


def download_http_video(url, destination):
    try:
        with urllib.request.urlopen(url) as response, open(destination, 'wb') as out_file:
            chunk_size = 8192
            while True:
                chunk = response.read(chunk_size)
                if not chunk:
                    break
                out_file.write(chunk)

        print(f"Download successful. Content saved to {destination}")

    except Exception as e:
        print(f"Error: {e}")


def download_http_video(url, destination_file):
    urllib.request.urlretrieve(url, destination_file)


def generate_video(extracted_text, assets_folder):
    words = extracted_text.split()
    video_clips = []

    for word in words:
        word_lower = word.lower()
        word_video_path = os.path.join(assets_folder, f'{word_lower}.mp4')

        if os.path.isfile(word_video_path):
            video_clip = VideoFileClip(word_video_path)
            video_clips.append(video_clip)

    if not video_clips:
        return

    final_clip = concatenate_videoclips(video_clips)

    with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as temp_video_file:
        temp_video_path = temp_video_file.name
        final_clip.write_videofile(temp_video_path, codec="libx264")

    return temp_video_path


def mediapipe_detection(image, model):

    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    image.flags.writeable = False
    results = model.process(image)
    image.flags.writeable = True

    image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

    return image, results


@app.route('/bot', methods=['GET'])
def chat():
    sequence = []
    sentence = []
    predictions = []
    threshold = 0.5
    video_path = request.args.get('video_path')
    url_to_download = "https://firebasestorage.googleapis.com/v0/b/sign-app-d3980.appspot.com/o/videos%2Fsample.mp4?alt=media&token=387c08bb-4f0a-4653-af15-832c14f66844"
    destination_file = "sample_video.mp4"
    download_http_video(url_to_download, destination_file)

    cap = cv2.VideoCapture("D:/final/final_app/python/sample_video.mp4")
    with mp_holistic.Holistic(min_detection_confidence=0.5, min_tracking_confidence=0.5) as holistic:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            image, results = mediapipe_detection(frame, holistic)
            print(results)

            draw_styled_landmarks(image, results)

            keypoints = extract_keypoints(results)
            sequence.append(keypoints)
            sequence = sequence[-30:]

            if len(sequence) == 30:
                res = model.predict(np.expand_dims(sequence, axis=0))[0]
                print(actions[np.argmax(res)])
                predictions.append(np.argmax(res))

                if np.unique(predictions[-10:])[0] == np.argmax(res):
                    if res[np.argmax(res)] > threshold:
                        if len(sentence) > 0:
                            if actions[np.argmax(res)] != sentence[-1]:
                                sentence.append(actions[np.argmax(res)])
                        else:
                            sentence.append(actions[np.argmax(res)])

                if len(sentence) > 5:
                    sentence = sentence[-5:]

                cv2.rectangle(image, (0, 0), (640, 40), (245, 117, 16), -1)
                cv2.putText(image, ' '.join(sentence), (3, 30),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)

            key = cv2.waitKey(10)
            if key == ord('q') or key == 27:
                break

    cap.release()
    cv2.destroyAllWindows()
    load_dotenv()

    API_KEY = os.environ.get("VAMSI_API_KEY")
    genai.configure(api_key=API_KEY)
    modeled = genai.GenerativeModel("gemini-pro")
    chat = modeled.start_chat(history=[])
    response = chat.send_message(sentence[0])
    video_text = response.text
    if video_text:
        assets_folder = 'final_app/python/assets1'  # Adjust path as needed
        sign_path = generate_video(video_text, assets_folder)
    firebase_destination_path = "video.mp4"
    upload_video_to_firebase(sign_path, firebase_destination_path)
    response = {
        'message': response.text,
    }
    return jsonify(response), 200


def run_flask_app():
    app.run(host='127.0.0.1', port=8000)


def draw_styled_landmarks(image, results):
    mp_drawing.draw_landmarks(image, results.pose_landmarks, mp_holistic.POSE_CONNECTIONS,
                              mp_drawing.DrawingSpec(
                                  color=(80, 22, 10), thickness=2, circle_radius=4),
                              mp_drawing.DrawingSpec(color=(80, 44, 121), thickness=2, circle_radius=2))
    mp_drawing.draw_landmarks(image, results.left_hand_landmarks, mp_holistic.HAND_CONNECTIONS,
                              mp_drawing.DrawingSpec(
                                  color=(121, 22, 76), thickness=2, circle_radius=4),
                              mp_drawing.DrawingSpec(color=(121, 44, 250), thickness=2, circle_radius=2))
    mp_drawing.draw_landmarks(image, results.right_hand_landmarks, mp_holistic.HAND_CONNECTIONS,
                              mp_drawing.DrawingSpec(
                                  color=(245, 117, 66), thickness=2, circle_radius=4),
                              mp_drawing.DrawingSpec(color=(245, 66, 230), thickness=2, circle_radius=2))


def extract_keypoints(results):
    pose = np.array([[res.x, res.y, res.z, res.visibility] for res in results.pose_landmarks.landmark]).flatten() \
        if results.pose_landmarks else np.zeros(33 * 4)
    lh = np.array([[res.x, res.y, res.z] for res in results.left_hand_landmarks.landmark]).flatten() \
        if results.left_hand_landmarks else np.zeros(21 * 3)
    rh = np.array([[res.x, res.y, res.z] for res in results.right_hand_landmarks.landmark]).flatten() \
        if results.right_hand_landmarks else np.zeros(21 * 3)
    return np.concatenate([pose, lh, rh])


# Load the model and actions before starting the Flask app
load_model_and_actions()

# Start Flask app in a separate thread
flask_thread = Thread(target=run_flask_app)
flask_thread.start()

# Wait for the server to start
time.sleep(2)
