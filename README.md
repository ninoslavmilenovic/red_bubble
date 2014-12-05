# RedBubble #

Creates a set of static HTML files for images for which there is EXIF data exported in the form of an *.xml file and used as an input file for this processor.

It takes the input file and produces a single HTML file, based on the output template given with this script, for each camera make, camera model and also an index.

The index HTML page contains:
- Thumbnail images for the first 10 work
- Navigation that allows the user to browse to all camera makes

Each Camera Make HTML page contains:
- Thumbnail images of the first 10 works for that camera make
- Navigation that allows the user to browse to the index page and to all camera models of that make

Each Camera Model HTML page contains:
- Thumbnail images of all works for that camera make and model
- Navigation that allows the user to browse to the index page and the camera make

The batch processor takes the location of the input file and the output directory as parameters.

## Install ##
Tested with Ruby 2.1.4
```bash
$ gem install cobravsmongoose
$ gem install tilt
```

## Tests ##
```bash
rspec html_generator_spec.rb
```
All tests should pass.

## Usage Example ##
```bash
$ ruby html_generator.rb works.xml static_html/
```
