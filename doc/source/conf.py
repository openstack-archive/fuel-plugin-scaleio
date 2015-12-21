# Always use the default theme for Readthedocs
RTD_NEW_THEME = True

extensions = []
templates_path = ['_templates']

source_suffix = '.rst'

master_doc = 'index'

project = u'The ScaleIO plugin for Fuel'
copyright = u'2015, EMC Corporation'

version = '1.0'
release = '1.0-1.0.1-1'

exclude_patterns = []

pygments_style = 'sphinx'

html_theme = 'classic'
html_static_path = ['_static']

latex_documents = [
  ('index', 'ScaleIO-Plugin_Guide.tex', u'The ScaleIO plugin for Fuel Documentation',
   u'EMC Corporation', 'manual'),
]

latex_elements = {
  'fncychap': '\\usepackage[Conny]{fncychap}',
  'classoptions': ',openany,oneside',
  'babel' : '\\usepackage[english]{babel}',
}
