update:
	sudo gem update
	bundle update

clean:
	bundle exec jekyll clean

serve:
	bundle exec jekyll serve

debug:
	bundle exec jekyll serve --trace --verbose
