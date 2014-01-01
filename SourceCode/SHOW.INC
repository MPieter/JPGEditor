; Methods
externdef showImage:FAR
externdef UpSampling:FAR
externdef changeColorSpace:FAR
externdef setPalette:FAR
externdef RenderScreen:FAR
externdef RestoreScreen:FAR

; Data (This is made available only for testing. Other methods schould not modify these blocks)
externdef RGBPalette:BYTE
externdef channel1:BYTE
externdef channel2:BYTE
externdef channel3:BYTE
externdef screenBuffer:BYTE