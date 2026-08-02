# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

import subprocess, os

os.makedirs('../../build/docs', exist_ok=True)
os.makedirs('_static', exist_ok=True)
os.makedirs('_templates', exist_ok=True)
subprocess.call('doxygen', shell=True)

# -- Project information -----------------------------------------------------

project = 'C47'
copyright = '2022-2024 The C47 Authors'
author = 'The C47 Authors'

# -- General configuration ---------------------------------------------------

extensions = [
  "breathe"
]

breathe_projects = { "C47": "../../build/docs/xml" }
breathe_default_project = "C47"
breathe_domain_by_extension = {"h": "c" , "c": "c"}

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = []


# -- Options for HTML output -------------------------------------------------

html_title = 'C47'
html_theme = 'furo'
html_static_path = ['_static']
