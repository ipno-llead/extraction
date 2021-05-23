Code for importing and processing board meeting minutes from different
jurisdictions. The goal is to extract information about police misconduct from
the text descriptions of disciplinary appeal hearings that appear within the
meeting minutes.

The code is organized into tasks and sub-tasks, any of which can be run from
the command line via [gnu make](https://www.gnu.org/software/make/). For more
on this project structure, see [The task is a quantum of
workflow](https://hrdag.org/2016/06/14/the-task-is-a-quantum-of-workflow/).

## Overview

The data import goes:

`import` -> `classify-pages` -> `segment` -> `extract` -> `export`

The `eda` task is for experimental code, and is not part of the data pipeline.

```bash
~/git/US-IP-NO/extraction/minutes
@ butterfly (0): find . -name Makefile | tree --fromfile -d
>> .
>> └── .
>>     ├── classify-pages
>>     │   ├── classify
>>     │   ├── export
>>     │   ├── features
>>     │   ├── import
>>     │   └── sample
>>     ├── eda
>>     ├── export
>>     ├── extract
>>     │   ├── classify-hearings
>>     │   ├── export
>>     │   ├── hearing-accused
>>     │   ├── import
>>     │   ├── meeting-dates
>>     │   └── merge
>>     ├── import
>>     │   ├── dl-dropbox
>>     │   ├── export
>>     │   ├── index
>>     │   └── ocr
>>     └── segment
>>         ├── classify
>>         ├── export
>>         ├── import
>>         └── sample
>> 
>> 26 directories
```

In order to update all extraction code, just run `make`. That will run the
associated subtasks in order, starting with `import` and ending with `export`:

```bash
~/git/US-IP-NO/extraction/minutes
@ butterfly (0): make
>> cd import && make
>> cd dl-dropbox && make
>> make[2]: Nothing to be done for `all'.
>> ...snip...
>> cd export && make
>> make[1]: Nothing to be done for `all'.
```

You can update just one step at a time by running `make` for that task:

```bash
~/git/US-IP-NO/extraction/minutes
@ butterfly (0): cd classify-pages && make
>> cd import && make
>> make[1]: Nothing to be done for `all'.
>> cd features && make
>> make[1]: Nothing to be done for `all'.
>> cd classify && make
>> make[1]: Nothing to be done for `all'.
>> cd export && make
>> make[1]: Nothing to be done for `all'.
```

A task without any sub-tasks will have a directory named `output` containing
its output. All tasks with sub-tasks have a sub-task named `export`.

## `import`

The `import` subtask downlaods files from dropbox, creates unique file
identifiers and extracts metadata from filenames, and converts file contents to
lines of text (currently by OCR-ing the PDF files, but soon to also convert
Word files, see issue #5).

```
~/git/US-IP-NO/extraction/minutes
@ butterfly (0): ls import/export/output/
>> metadata.csv  minutes.parquet

~/git/US-IP-NO/extraction/minutes
@ butterfly (0): head import/export/output/metadata.csv | head -1 | tr '|' '\n'
>> fileid
>> region
>> year
>> month
>> day
>> file_category
>> npages
>> filepath
>> filesha1
>> db_id
>> db_path
>> db_content_hash
```

Note that `year`, `month`, `day`, and `file_category` are inferred based on the
file name. The file categories:

```
~/git/US-IP-NO/extraction/minutes
@ butterfly (0): cut import/export/output/metadata.csv -d'|' -f6 | \
    sort | \
    uniq -c | \
    sort
>>       1 file_category
>>       4 memo
>>       7 transcript
>>      24 other
>>      56 agenda
>>     289 minutes
```

Currently, we're only doing data extraction from the `minutes` file types. For
progress on the `transcript` type, follow issue #6. Some of the documents
labeled `other` contain additional meeting minutes and/or attachments and
testimonies, and will require additional thought.

## `classify-pages`

This task classifies each page as one of "meeting (front)", "hearing (front)",
"agenda (front)" or "continuation", and then uses those classifications to
split up files into distinct documents, keyed by `docid`. Update via `cd
classify-pages && make`, which creates
`classify-pages/export/output/minutes.parquet`

## `segment`

This task classifies each line as one of `meeting_header`, `hearing_header`,
`hearing`, `roll_call`, or `other`, in order to facilitate extraction of
meeting date and information from disciplinary appeal hearings. Update the task
via `cd segment && make`.

In order to improve the `segment` task, we need to sample and label training
data. The `segment/sample` task does the sampling, and outputs a file called
`training-data.xlsx` as well as a directory called `training-data` consisting
of label-able Excel files. `segment/sample` is not run by default, but can be
run explicitly via `make sample`:

```
~/git/US-IP-NO/extraction/minutes/segment
@ butterfly (0): cd sample

~/git/US-IP-NO/extraction/minutes/segment
@ butterfly (0): tree -d sample
>> sample
>> └── src
>> 
>> 1 directory, 3 files

~/git/US-IP-NO/extraction/minutes/segment
@ butterfly (0): make sample
>> cd import && make
>> ...snip...

~/git/US-IP-NO/extraction/minutes/segment
@ butterfly (0): tree -d sample
>> sample
>> ├── output
>> │   └── training-data
>> └── src
```

## `extract`

`extract/export/output/all-hearings.xlsx` contains all extracted data, and
`extract/export/output/docs` contains extracted hearings organized as one
hearing per text file. Hearings are classified as `police`, `fire`, or `other`:

```
@ butterfly (0): find extract/export/output/docs -iname *.txt | head -3
>> extract/export/output/docs/fire/bd4fb321-001.txt
>> extract/export/output/docs/fire/9d782bad-002.txt
>> extract/export/output/docs/fire/72656aef-001.txt

@ butterfly (0): find extract/export/output/docs -iname *.txt | cut -d'/' -f5 | sort | uniq -c
>>     163 fire
>>      92 police
>>     106 unknown
```
