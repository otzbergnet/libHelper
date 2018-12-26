# Open Access Helper for Safari

## Why this document

Protecting your privacy should be your number one concern, when installing a browser extension, like Open Access Helper for Safari. The purpose of this document is to provide you with insight into the code, so that you can be assured that the code itself respects your privacy and indeed only does what I say it does.

If you've come mainly to check on the privacy of the app, you will want to get started with the following two documents:

1. [script.js](https://github.com/otzbergnet/libHelper/blob/master/Open%20Access%20Helper%20Safari/script.js) - is injected into the page
2. [SafariExtensionHandler.swift](https://github.com/otzbergnet/libHelper/blob/master/Open%20Access%20Helper%20Safari/SafariExtensionHandler.swift) - all the busines logic of the app

## What does this App do

Open Access Helper for Safari is a Safari App Extension, which will identify Digital Object Identifiers (DOI) within the page's source code (meta-tags) and then use [unpaywall.org API](https://unpaywall.org) to find a legal Open Access copy for the document you are viewing.

The app will also follow the returned link, which often points to https://dx.doi.org/{DOI} to see whether you might already be at the Open Access version.

## Can you be more specific?

The app will perform the following operations

1. Check, if the code was injected in an iframe, if so it will not execute
2. Try to identify a DOI on the page, to avoid playing with Regular Expressions, we are checking for meta-tags such as 'citation_doi', 'doi', 'dc.doi', 'dc.identifier', 'dc.identifier.doi', 'bepress_citation_doi', 'rft_id', 'dcsext.wt_doi'
3. The DOI is then sent to unpaywall.org
4. If Unpaywall.org doesn't know of a legal Open Access copy, the app will stop here
5. If a legal Open Access copy is known, an orange button is injected and the toolbar icon gets an exclamation mark badge - clicking either takes you to the item
6. After injecting the orange button, the app follows the link to see if you possibly are on the page already, if you are, the button changes color to green and the toolbar icon gets a checkmark badge

To help you recognize that the app is actively doing something, the icon changes from an outline to a filled padlock

Additionally the App will allow you to highlight text and select the context menu to start a search at base-search.net

## About the code

This app is a hobby project, I am sure there is plenty in the code that isn't perfect or best practice. If you see something, feel free to open an issue.

## Copyright

I guess there is Copyright and I guess it is mine ;)

## Contact

[eMail](mailto:oahelper@otzberg.net)<br/>
[App Website](https://www.otzberg.net/oahelper)