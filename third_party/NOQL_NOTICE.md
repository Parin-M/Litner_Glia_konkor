# Third-party AI model notice

Glia Konkor packages the **shekar-ai/Noql** Persian sentence-embedding model for fully offline semantic features.

- Model: shekar-ai/Noql
- Parameters: 11.9M
- License: Apache License 2.0
- Model page: https://huggingface.co/shekar-ai/Noql
- Base encoder lineage includes ALBERT and the Persian ALBERT checkpoint from the Shekar project.

The APK build downloads the model from Hugging Face, converts it to an ONNX representation and quantizes its weights for on-device Android inference. No network connection is required at application runtime.
