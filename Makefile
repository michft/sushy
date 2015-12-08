# Set these if not defined already
export BIND_ADDRESS?=0.0.0.0
export PORT?=8080
export DEBUG?=False
export PROFILER?=False
export CONTENT_PATH?=pages
export THEME_PATH?=themes/wiki
export DATABASE_PATH?=/tmp/sushy.db
export SITE_NAME?=Sushy
export NEW_RELIC_APP_NAME?=$(SITE_NAME)
export NEW_RELIC_LICENSE_KEY?=''
export PYTHONIOENCODING=UTF_8:replace
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Experimental zip bundle
BUNDLE=sushy.zip
export PYTHONPATH=$(BUNDLE)

# Source code
HYFILES=$(wildcard sushy/*.hy)
PYFILES=$(wildcard sushy/*.py)
BYTECODE=$(HYFILES:.hy=.pyc)
PYTHONCODE=$(HYFILES:.hy=.py)
PROFILES=$(wildcard *.pstats)
CALL_DIAGRAMS=$(PROFILES:.pstats=.png)

repl:
	hy -i "(import sushy.app)"

deps:
	pip install -U -r requirements.txt

clean:
	rm -f *.zip
	rm -f $(BYTECODE)
	rm -f $(PYTHONCODE)
	rm -f $(DATABASE_PATH)*

# Turn Hy files into bytecode so that we can use a standard Python interpreter
%.pyc: %.hy
	hyc $<

# Turn Hy files into Python source so that PyPy will be happy
%.py: %.hy
	hy2py $< > $@

build: $(BYTECODE) 

# Experimental bundle to see if we can deploy this solely as a ZIP file
bundle: $(HYFILES) $(PYFILES)
	zip -r9 $(BUNDLE) sushy/* -i *.py *.pyc
	rm -f sushy/*.pyc

# Run with the embedded web server
serve: build
	python -m sushy.app

# Run with uwsgi
uwsgi: build
ifneq ($(NEW_RELIC_LICENSE_KEY),'')
	newrelic-admin run-program uwsgi --http :$(PORT) --python-path . --wsgi sushy.app --callable app --gevent 2000 -p 1 
endif
	uwsgi --http :$(PORT) --python-path . --wsgi sushy.app --callable app --gevent 2000 -p 1 

# Run with uwsgi
uwsgi-ini: build
	uwsgi --ini uwsgi.ini

# Run indexer
index: build
	python -m sushy.indexer

# Run indexer and watch for changes
index-watch: build
ifneq ($(NEW_RELIC_LICENSE_KEY),'')
	newrelic-admin run-python -m sushy.indexer watch
endif
	python -m sushy.indexer watch

# Render pstats profiler files into nice PNGs (requires dot)
%.png: %.pstats
	python tools/gprof2dot.py -f pstats $< | dot -Tpng -o $@

profile: $(CALL_DIAGRAMS)
