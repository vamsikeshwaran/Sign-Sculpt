import speech_recognition as sr
from flask import Flask, request, jsonify
from moviepy.editor import VideoFileClip, concatenate_videoclips
import os
import tempfile
from gtts import gTTS
from googletrans import Translator
import traceback
import openai
import requests
from twilio.rest import Client
from textblob import TextBlob
import pandas as pd
import numpy as np
from firebase_admin import credentials, initialize_app, storage
from google.cloud.exceptions import NotFound

app = Flask(__name__)

cred = credentials.Certificate(
    "D:/final/final_app/python/serviceAcc.json")
initialize_app(cred, {"storageBucket": "htmlapp-fa3bc.appspot.com"})


def upload_video_to_firebase(video_path, destination_path):
    try:

        bucket = storage.bucket()

        video_file = video_path
        destination_blob = destination_path

        blob = bucket.blob(destination_blob)
        blob.upload_from_filename(video_file)

        print(f"Video uploaded to {blob.public_url}")

    except NotFound as e:
        print(f"Error: Bucket or path not found - {e}")

    except Exception as e:
        print(f"Error uploading video - {e}")


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


@app.route('/sign', methods=['GET'])
def main():
    text_path = request.args.get('text')
    translated_text = text_path

    if translated_text:
        assets_folder = 'D:/final/final_app/python/assets1'  # Adjust path as needed
        video_path = generate_video(translated_text, assets_folder)

        
        response = {
            'message': "Success",
        }
        firebase_destination_path = "video.mp4"
        upload_video_to_firebase(video_path, firebase_destination_path)
        return jsonify(response), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)