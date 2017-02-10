#!/usr/bin/env bash

doxygen doxygen/Doxyfile  # doxygen docs

epydoc --config Epydoc_dvi  # epydoc docs
epydoc --config Epydoc_html
epydoc --config Epydoc_latex
epydoc --config Epydoc_pdf
epydoc --config Epydoc_ps
epydoc --config Epydoc_text
