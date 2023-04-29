update:
	sudo gem update
	bundle update

clean:
	bundle exec jekyll clean

serve:
	bundle exec jekyll serve --host 0.0.0.0

debug:
	bundle exec jekyll serve --host 0.0.0.0 --trace --verbose

locate-theme:
	bundle show minima
