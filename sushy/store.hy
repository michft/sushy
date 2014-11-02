(import 
    [os [walk stat]]
    [os.path [join exists splitext]]
    [stat [ST_MTIME]]
    [logging [getLogger]]
    [codecs [open]]
    [config [*ignored-folders* *base-types* *base-filenames* *store-path*]])

(setv log (getLogger))


(defn strip-seq [string-sequence]
    (map (fn [buffer] (.strip buffer)) string-sequence))
    

(defn split-header-line [string]
    (if (.startswith "---" string) ; handle Jekyll-style front matter delimiters
       ["jekyll" "true"]
       (let [[parts (list (strip-seq (.split string ":" 1)))]]
          [(.lower (get parts 0)) (get parts 1)])))
            

(defn parse-page [buffer &optional [content-type "text/plain"]]
    ; parse a page and return a header map and the raw markup
    (try 
        (let [[parts        (.split buffer "\n\n" 1)]
              [header-lines (.splitlines (get parts 0))]
              [headers      (dict (map split-header-line header-lines))]
              [body         (get parts 1)]]
              (if (not (in "content-type" headers))
                (assoc headers "content-type" content-type))
              {:headers headers
               :body    body})
        (catch [e Exception]
            (.exception log "Could not parse page")
            (throw (IOError "Invalid Page Format.")))))


(defn open-asset [pagename asset]
    (let [[filename (join *store-path* pagename asset)]]
        (open filename "rb")))


(defn get-page [pagename]
    ; return the raw data for a page 
    (.debug log (join *store-path* pagename))
    (let [[path         (join *store-path* pagename)]
          [page         (.next (filter (fn [item] (exists (join path item))) *base-filenames*))]
          [filename     (join *store-path* pagename page)]
          [content-type (get *base-types* (get (splitext page) 1))]]
        (parse-page
          (.read
            (apply open [filename] {"mode" "r" "encoding" "utf-8"})) content-type)))


(defn filtered-names [folder-list]
    (filter (fn [folder-name] (not (in folder-name *ignored-folders*))) folder-list))


(defn scan-pages [root-path]
    (let [[pages {}]]
        (for [elements (walk root-path)]
            (let [[folder     (get elements 0)]
                  [subfolders (get elements 1)]
                  [files      (get elements 2)]]
                ; setting this helps guide os.path.walk()
                (setv subfolders (filtered-names subfolders))
                (for [base *base-filenames*]
                     (if (in base files)
                         (assoc pages
                             (slice folder (+ 1 (len root-path)))
                             {:filename base
                              :mtime (get (stat (join folder base)) ST_MTIME)})))))
        pages))

