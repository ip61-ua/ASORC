TEX = pdflatex
PROJECT = document
OUT_LITE = $(PROJECT)_lite
BUILD_DIR = build
BULLSHIT = SUPERMEMORIA
L = $(BULLSHIT)/linux
U = $(BULLSHIT)/unix
W = $(BULLSHIT)/windows
USELESS = *.aux *.log *.out *.toc
COMPRESS = zip
RESULT = asorc_practica3.zip

all:
	$(TEX) $(PROJECT).tex
	$(TEX) $(PROJECT).tex
	$(TEX) $(PROJECT).tex

convert:
	gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=$(OUT_LITE).pdf $(PROJECT).pdf

tiny: convert
	mv $(OUT_LITE).pdf $(PROJECT).pdf

zip:
	rm -rf $(BUILD_DIR) $(RESULT)
	mkdir -p $(BUILD_DIR)/doc
	cp $(PROJECT).pdf $(BUILD_DIR)/doc
	cp -r $(L) $(BUILD_DIR)
	cp -r $(U) $(BUILD_DIR)
	cp -r $(W) $(BUILD_DIR)
	$(COMPRESS) -r $(RESULT) $(BUILD_DIR)/*

clean:
	rm -f $(USELESS) $(RESULT)