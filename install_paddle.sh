#!/bin/bash

VENV_NAME="pp"
PADDLEOCR_FOLDER="PaddleOCR"
PADDLEOCR_REPO_URL="https://github.com/PaddlePaddle/PaddleOCR.git"
INPUT_FILE="requirements.txt"
RE_LINK="PUT THE GDRIVE LINK OF RE"
SER_LINK="PUT THE GDRIVE LINK OF SER"
RE_FOLDER="re_vi_layoutxlm_xfund_infer"
SER_FOLDER="ser_vi_layoutxlm_xfund_infer"

#creating and activating virtual env
if [ -d "$VENV_NAME" ]; then
  echo "Virtual environment '$VENV_NAME' already exists 😒"
else
  python3 -m venv "$VENV_NAME"
  echo "Virtual environment '$VENV_NAME' created 🥳🥳"
fi

. "$VENV_NAME/bin/activate"
echo "Virtual environment '$VENV_NAME' activated 😉😉"
echo $VIRTUAL_ENV

echo ""

#Cloning and moving into PaddleOCR folder
if [ -d "$PADDLEOCR_FOLDER" ]; then
  echo "PaddleOCR folder already exists 😒, Skipping cloning 🥱"
else
  git clone "$PADDLEOCR_REPO_URL" "$PADDLEOCR_FOLDER"
fi

cd PaddleOCR
echo $(pwd)

#Upgrading MyMuPDF's version in requirements.txt
if [ ! -f "$INPUT_FILE" ]; then
  echo "Input file '$INPUT_FILE' not found."
  exit 1
fi
sed 's/PyMuPDF<1.21.0/PyMuPDF/g' "$INPUT_FILE" > temp.txt
mv temp.txt "$INPUT_FILE"

#Pip installing requirements.txt files
if command -v pip > /dev/null 2>&1; then
  PIP_COMMAND="pip"
elif command -v pip3 > /dev/null 2>&1; then
  PIP_COMMAND="pip3"
else
  echo "Error: 'pip' and 'pip3' commands not found. Please install Python and ensure 'pip' or 'pip3' is in your PATH."
  exit 1
fi

#pip installs
$PIP_COMMAND install --upgrade $PIP_COMMAND setuptools wheel
$PIP_COMMAND install -r requirements.txt
$PIP_COMMAND install -r ppstructure/kie/requirements.txt
$PIP_COMMAND install "paddleocr>=2.0.1"
if pip show paddleocr >/dev/null 2>&1; then
  echo "paddleocr is installed. 😇"
else
  echo "paddleocr is not installed. Exiting. 😓"
  exit 1
fi

#download inference models
if [ ! -d "inference" ]; then
  echo "Creating the 'inference' folder...😮‍💨"
  mkdir "inference"
fi

cd "inference" || exit 1
$PIP_COMMAND install gdown

if [ ! -d "$RE_FOLDER" ]; then
  echo "The '$RE_FOLDER' folder doesn't exist. Downloading $RE_FOLDER.tar..."
  gdown --fuzzy $RE_LINK

  # Untar the downloaded file
  echo "$RE_FOLDER.tar..."
  tar -xf "$RE_FOLDER.tar"

  # Optionally, remove the tar file if not needed
  rm $RE_FOLDER.tar
else
  # Folder exists, do nothing
  echo "The '$RE_FOLDER' folder already exists. Skipping download. 😬"
fi

if [ ! -d "$SER_FOLDER" ]; then
  echo "The '$SER_FOLDER' folder doesn't exist. Downloading $SER_FOLDER.tar..."
  gdown --fuzzy $SER_LINK

  # Untar the downloaded file
  echo "$SER_FOLDER.tar..."
  tar -xf "$SER_FOLDER.tar"

  # Optionally, remove the tar file if not needed
  rm $SER_FOLDER.tar
else
  # Folder exists, do nothing
  echo "The '$SER_FOLDER' folder already exists. Skipping download. 😬"
fi

cd ..
cd ppstructure
echo "SER inference 😉"
$PIP_COMMAND install paddlepaddle
python3 kie/predict_kie_token_ser.py \
  --kie_algorithm=LayoutXLM \
  --ser_model_dir=../inference/ser_vi_layoutxlm_xfund_infer \
  --image_dir=./docs/kie/input/zh_val_42.jpg \
  --ser_dict_path=../train_data/XFUND/class_list_xfun.txt \
  --vis_font_path=../doc/fonts/simfang.ttf \
  --ocr_order_method="tb-yx"

echo "RE inference 😉"
cd ppstructure
python3 kie/predict_kie_token_ser_re.py \
  --kie_algorithm=LayoutXLM \
  --re_model_dir=../inference/re_vi_layoutxlm_xfund_infer \
  --ser_model_dir=../inference/ser_vi_layoutxlm_xfund_infer \
  --use_visual_backbone=False \
  --image_dir=./docs/kie/input/zh_val_42.jpg \
  --ser_dict_path=../train_data/XFUND/class_list_xfun.txt \
  --vis_font_path=../doc/fonts/simfang.ttf \
  --ocr_order_method="tb-yx"
