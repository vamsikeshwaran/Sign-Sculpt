from flask import Flask, request, jsonify
import moviepy.editor as mp
from moviepy.editor import VideoFileClip, concatenate_videoclips, clips_array
import os
import speech_recognition as sr
from googletrans import Translator
import tempfile
import urllib.request
from firebase_admin import credentials, initialize_app, storage
from google.cloud.exceptions import NotFound

app = Flask(__name__)
translator = Translator()


cred = credentials.Certificate(
    "D:/final/final_app/python/serviceAccount.json")
initialize_app(cred, {"storageBucket": "newfinalvideo.appspot.com"})


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


def merge_letter_videos(word, assets_folder):
    letter_clips = []

    for letter in word:
        letter_lower = letter.lower()
        letter_video_path = os.path.join(assets_folder, f'{letter_lower}.mp4')

        if os.path.isfile(letter_video_path):
            letter_clip = VideoFileClip(letter_video_path)
            letter_clips.append(letter_clip)
        else:
            print(f"No video found for letter: {letter_lower}")

    if not letter_clips:
        print("No valid videos found for the word.")
        return None

    final_clip = concatenate_videoclips(letter_clips)
    return final_clip


def merge_word_videos(words, assets_folder):
    video_clips = []

    for word in words:
        word_lower = word.lower()
        word_video_path = os.path.join(assets_folder, f'{word_lower}.mp4')

        if os.path.isfile(word_video_path):
            video_clip = VideoFileClip(word_video_path)
            video_clips.append(video_clip)
        else:
            print(f"No video found for word: {word_lower}")
            print(f"Splitting '{word}' into letters...")
            letter_video = merge_letter_videos(word, assets_folder)
            if letter_video is not None:
                video_clips.append(letter_video)

    if not video_clips:
        print("No valid videos found.")
        return None

    final_clip = concatenate_videoclips(video_clips)
    return final_clip


def extract_audio_as_text(video_path):
    video = mp.VideoFileClip(video_path)
    audio = video.audio

    temp_audio_path = "temp_audio.wav"
    audio.write_audiofile(temp_audio_path)

    r = sr.Recognizer()

    with sr.AudioFile(temp_audio_path) as source:
        audio_data = r.record(source)
        audio_text = r.recognize_google(audio_data)

    return audio_text

def translate_to_hindi(text):
    translator = Translator()
    translated_text = translator.translate(text, dest='hi').text
    return translated_text

@app.route('/generate_combined_video', methods=['GET'])
def generate_combined_video():
    video_path = request.args.get('video_path')
    url_to_download = "https://firebasestorage.googleapis.com/v0/b/sign-app-d3980.appspot.com/o/videos%2Fsample.mp4?alt=media&token=387c08bb-4f0a-4653-af15-832c14f66844"
    destination_file = "sample_video.mp4"
    download_http_video(url_to_download, destination_file)

    extracted_text = extract_audio_as_text(
        'D:/final/final_app/python/sample_video.mp4')
    translation = translator.translate(extracted_text, src="hi", dest="en")
    translated_text = translation.text
    hindi_text = translate_to_hindi(translated_text)

    if not (extracted_text and video_path):
        return jsonify({'error': 'Invalid request. Missing required parameters.'}), 400

    assets_folder = 'D:/final/final_app/python/assets1'

    words = translated_text.split()

    if not words:
        return jsonify({'error': 'Please enter a valid sentence.'}), 400

    video = merge_word_videos(words, assets_folder)

    if video is None:
        return jsonify({'error': 'No valid videos found.'}), 400

    continuous_video_path = "output_continuous_video.mp4"
    video.write_videofile(continuous_video_path, codec="libx264")

    uploaded_video = VideoFileClip(video_path)
    uploaded_video = uploaded_video.resize(height=video.h)

    final_video = clips_array([[uploaded_video, video]])

    final_video_path = "final_combined_video.mp4"
    final_video.write_videofile(final_video_path, codec="libx264")

    os.remove(continuous_video_path)

    response = {
        'message': translated_text,
        'combined_video_path': final_video_path
    }
    local_video_path = "D:/final/final_app/python/final_combined_video.mp4"
    firebase_destination_path = "video.mp4"
    upload_video_to_firebase(local_video_path, firebase_destination_path)

    return jsonify(response), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)