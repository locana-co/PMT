# PMT Database Documentation

The following is a listing of PMT Database documentation resources. The
following resources reflect the most recent iteration of development for
the database. The PMT Database is currently at version **3.0** iteration 
**10**.

* [Data Dictionary](DataDictionary.md) - A comprehensive documentation of
all the tables and fields in the PMT Database. This is also available in
[pdf format](PMT-DataDictionary.pdf).

* [Function Reference](Functions.md) - A comprehensive documentation of
all the available functions in the PMT Database. This is also available in
[pdf format](PMT-Functions.pdf). **In the process of 
updating all functions to iteration 10**

* [Schema Diagram](PMT-Schema.pdf) - A entity relationship diagram of the
tables and their relationships to one another.

* [IATI Compatibility](IATI.md) - Comprehensive documentation of how the PMT 
database is compatible with the 
[**IATI (_International Aid Transparency Initiative_) Standards**](http://iatistandard.org/).
This is also available in [pdf format](PMT-IATICompatability.pdf).

* [Understanding the Data Model](Understanding the Data Model.pdf) - An 
explanatory document on some of the key concepts in the data model that 
makes PMT a powerful, flexible & scalable.


## Maintenance Notes

The pdf versions of the documenation resources for the data dictionary and
the functions reference are created from the markdown source documents, using
an open source tool called [Pandoc](http://pandoc.org/). From the documenation
repo folder execute the following from a command prompt with pandoc installed:

```
-- data dictionary
pandoc -o DataDictionary.docx DataDictionary.md
-- function reference
pandoc -o Functions.docx Functions.md
-- IAIT documentation
pandoc -o IATI.docx IATI.md

```

Open the created Word document and save as a pdf with the prefix name "PMT-", 
replacing existing document.
