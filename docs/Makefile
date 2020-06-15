all: main.pdf

%.pdf: %.tex
	pdftex -file-line-error -halt-on-error -interaction nonstopmode $^
	pdftex -file-line-error -halt-on-error -interaction nonstopmode $^

clean:
	rm *.pdf

.PHONY: clean
