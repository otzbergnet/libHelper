var loaded = 0;
document.addEventListener("DOMContentLoaded", function(event) {
    //check if we are in an iframe, if so do nothing, otherwise go and find yourself a DOI

    if(!inIframe() && loaded == 0){
        loaded++;
        findDoi();
    }
                          
});

//I must really like the good folk at impactstory to work around their SPA :)
if(window.location.hostname == "gettheresearch.org"){
    let url = location.href;
    document.addEventListener('click', ()=>{
        requestAnimationFrame(()=>{
            if(url!==location.href){
                removeMyself()
                findDoi3();
                
            }
            url = location.href;
        });
    }, true);
}


// double checking that we are not in an iFrame

if(!inIframe()){
    // Listens for messages sent from the app extension's Swift code.
    safari.self.addEventListener("message", messageHandler);
    document.addEventListener("contextmenu", handleContextMenu, false);
    document.addEventListener("keydown", fireOnKeypress, false);
}


//support gettheresearch SPA
function removeMyself(){
    var element = document.getElementById('doifound_outer');
    if(element != null){
      element.parentNode.removeChild(element);
      safari.extension.dispatchMessage("notfound", {"doi" : ""});
    }
}


// handles the requests from the SafariExtensionHandler
function messageHandler(event){
    if (event.name === "doi"){
        console.log("message doi to handle")
        findDoi();
    }
    else if (event.name === "url"){
        currentUrl();
    }
    else if (event.name === "oafound"){
        document.body.dataset.oahdoire = "1";
        oafound(event.message);
    }
    else if (event.name === "onoa"){
        document.body.dataset.oahdoire = "2";
        onOa(event.message);
    }
    else if (event.name === "printPls"){
        console.log(event.message);
    }
    else if (event.name == "getOAUrl"){
        getKnownOAUrl();
    }
    else if (event.name == "notoadoi"){
        document.body.dataset.oahdoire = "0";
        alternativeOA();
    }
    else if (event.name == "showAlert"){
        if(event.message.type == "alert"){
            alert(event.message.msg);
        }
        else if(event.message.type == "confirm"){
            handleConfirmRequest(event.message.msg);
        }
    }
    else if (event.name == "tabevaluate"){
        evaluateTab();
    }
}

function findDoi(){
    //console.log("Open Acces Helper: DOI0");
    // we are going to look in meta-tags for the DOI
    var option = ['citation_doi', 'doi', 'dc.doi', 'dc.identifier', 'dc.identifier.doi', 'bepress_citation_doi', 'rft_id', 'dcsext.wt_doi', 'DC.identifier'];
    var doi = "";
    for(i = 0; i < option.length; i++){
        doi = getMeta(option[i]);
        if(doi != ""){
            break;
        }
    }
    if(doi != ""){
        cleanedDOI = cleanDOI(doi)
        console.log("Open Access Helper (Safari Extension) found this DOI (0): "+cleanedDOI)
        var url = encodeURI(location.href);
        safari.extension.dispatchMessage("found", {"doi" : cleanedDOI, "url" : url});
    }
    else{
        // didn't find a DOI yet, so let's look in another place
        findDoi1();
    }
    
}

function findDoi1(){
    //console.log("Open Acces Helper: DOI1");
    //in this case, we are looking for both meta-tag and its scheme
    var doi = getMetaScheme('dc.Identifier', 'doi');
    if(doi != ""){
        console.log("Open Access Helper (Safari Extension) found this DOI (1): "+doi)
        var url = encodeURI(location.href);
        safari.extension.dispatchMessage("found", {"doi" : doi, "url" : url});
    }
    else{
        // didn't find a DOI yet, let's look in yet another place
        findDoi2();
    }
}

function findDoi2(){
    //console.log("Open Acces Helper: DOI2");
    // this is a place for more complex fallbacks, where we can provide additional "CSS-Selectors" to find
    // a DOI. Right now it really only handles a single case, but hopefully there will be aditional cases
    // in future
    var selectors = ['a[ref=\"aid_type=doi\"]'];
    var doi = ""
    for(i = 0; i < selectors.length; i++){
        doi = getFromSelector(selectors[i]);
        if(doi != ""){
            break;
        }
    }
    if(doi != ""){
        console.log("Open Access Helper (Safari Extension) found this DOI (2): "+doi)
        var url = encodeURI(location.href);
        safari.extension.dispatchMessage("found", {"doi" : doi, "url" : url});
    }
    else{
        // we are ready to give up here, but not quite
        findDoi3();
    }
}

function findDoi3(){
    //console.log("Open Acces Helper: DOI3");
    // if we cannot work through specific selectors, a more general scraping approach might be neeeded
    // to avoid doing this on every page, we specify the pages we support
    
    var host = window.location.hostname;
    if(host.indexOf("ieeexplore.ieee.org") > -1){
        // IEEE
        var regex = new RegExp('"doi":"([^"]+)"');
        var doi = runRegexOnDoc(regex);
        if(doi != false){
            scrapedDoi(doi);
        }
        else{
            alternativeOA();
        }
    }
    else if(host.indexOf("nber.org") > -1){
        //National Bureau of Economic Research
        var regex = new RegExp('Document Object Identifier \\(DOI\\): (10.*?)<\\/p>');
        var doi = runRegexOnDoc(regex);
        
        scrapedDoi(doi);
        
    }
    else if(host.indexOf("base-search.net") > -1){
        // BASE SEARCH - for detail view, really quite superflous, but I like base
        if (document.querySelectorAll("a.link-orange[href^=\"https://doi.org/\"]").length > 0){
            var doi = document.querySelectorAll("a.link-orange[href^=\"https://doi.org/\"]")[0].href.replace('https://doi.org/','').replace('http://doi.org/','');
            scrapedDoi(doi);
        }
        else{
            alternativeOA();
        }
    }
    else if(host.indexOf("gettheresearch.org") > -1){
        console.log("Open Access Helper (Safari Extension) - support for gettheresearch.org is experimental")
        // GetTheResearch.org- for detail view, really quite superflous, but I like base
        if(window.location.search.indexOf("zoom=") > -1){
            var potentialDoi = getQueryVariable("zoom");
            scrapedDoi(potentialDoi);
        }
    }
    else{
        //console.log("Open Acces Helper: Failed on DOI3");
        // we are ready to give up here and send a notfound message, so that we can deactivate the icon
        safari.extension.dispatchMessage("notfound", {"doi" : ""});
        // however we'll continue look at the alternativeOA Webscraping methods
        alternativeOA();
    }
}


function getMeta(metaName) {
    // get meta tags and loop through them. Looking for the name attribute and see if it is the metaName
    // we were looking for
    const metas = document.getElementsByTagName('meta');
    
    for (let i = 0; i < metas.length; i++) {
        if (metas[i].getAttribute('name') === metaName) {
            return metas[i].getAttribute('content');
        }
    }
    
    return '';
}

function getMetaScheme(metaName, scheme){
    // pretty much the same as the other function, but it also double-checks the scheme
    const metas = document.getElementsByTagName('meta');
    
    for (let i = 0; i < metas.length; i++) {
        if (metas[i].getAttribute('name') === metaName && metas[i].getAttribute('scheme') === scheme) {
            return metas[i].getAttribute('content');
        }
    }
    
    return '';
}

function getFromSelector(selector){
    // allow for more complex CSS selectors, these are likely more unreliable
    const elements = document.querySelectorAll(selector);
    
    for (let i = 0; i < elements.length; i++) {
        // make sure we test what we find to be a proper DOI
        if(isDOI(elements[i].innerHTML)){
            return elements[i].innerHTML
        }
    }
    
    return '';
}

function getQueryVariable(variable) {
    var query = window.location.search.substring(1);
    var vars = query.split('&');
    for (var i = 0; i < vars.length; i++) {
        var pair = vars[i].split('=');
        if (decodeURIComponent(pair[0]) == variable) {
            return decodeURIComponent(pair[1]);
        }
    }
}

function cleanDOI(doi){
    
    // clean for a few common known prefixes (well exactly one right now, but easy to expand
    var clean = ['info:doi/'];
    
    for(let i = 0; i < clean.length; i++){
        doi = doi.replace(clean[i], '');
    }
    
    return doi;
}

function isDOI(doi){
    
    // these regular expressions were recommended by CrossRef in a blog post
    // https://www.crossref.org/blog/dois-and-matching-regular-expressions/
    var regex1 = /^10.\d{4,9}\/[-._;()\/:A-Z0-9]+$/i;
    var regex2 = /^10.1002\/[^\s]+$/i;
    var regex3 = /^10.\d{4}\/\d+-\d+X?(\d+)\d+<[\d\w]+:[\d\w]*>\d+.\d+.\w+;\d$/i;
    var regex4 = /^10.1021\/\w\w\d+$/i;
    var regex5 = /^10.1207\/[\w\d]+\&\d+_\d+$/i;
    
    if(regex1.test(doi)) {
        return true;
    }
    else if (regex2.test(doi)){
        return true;
    }
    else if (regex3.test(doi)){
        return true;
    }
    else if (regex4.test(doi)){
        return true;
    }
    else if (regex5.test(doi)){
        return true;
    }
    else {
        return false;
    }
}


function currentUrl() {
    return safari.application.activeBrowserWindow.activeTab.url;
}

function oafound(message){

    // here we inject the icon into the page
    // room for improvement, most Chrome extensions would inject an iFrame
    
    var src = safari.extension.baseURI + "sec30.png"; // padlock

    var div = document.createElement('div');
    div.innerHTML = '<div class="doifound" onclick="window.open(\''+message.url+'\')" title="'+message.title+message.url+'"><img id="doicheckmark" src="'+src+'" title="'+message.title+message.url+'" data-oaurl="'+message.url+'" data-badge="!"/></div><span id="OAHelperLiveRegion" role="alert" aria-live="assertive" aria-atomic="true"></span>'; // data-oaurl is a gift to ourselves
    div.id = 'doifound_outer'
    div.className = 'doifound_outer'
    
    if(document.body.parentNode.parentNode != "#document"){
        document.body.appendChild(div);
    }
    console.log("Open Access Helper (Safari Extension) found this Open Access URL ("+message.source+"): "+message.url)
    var currentUrl = window.location.href;
    safari.extension.dispatchMessage("compareURL", {"current" : currentUrl, "goto" : message.url});
    var trackCall = setInterval(function () {
        var div = document.getElementById("OAHelperLiveRegion");
        div.innerHTML = message.title;
        clearInterval(trackCall);
    }, 4000);
}

// if on Open Access document, this will turn the injected badge / button green

function onOa(message){
    var div = document.getElementById("doifound_outer");
    div.classList.add("doigreen");
    var div1 = document.getElementById("doicheckmark");
    div1.dataset.badge = "✔"
    var trackCall = setInterval(function () {
        var div = document.getElementById("OAHelperLiveRegion");
        div.innerHTML = message.title;
        clearInterval(trackCall);
    }, 8000);
}


// unused function, leaving it here, in case I ever want to make the
// injected div go away
function countDown(){
    var i = 0;
    var id = document.getElementById("cntdwn");
    var trackCall = setInterval(function () {
        if (i == 25) {
            clearInterval(trackCall);
        }
        else{
            id.innerHTML = 9-i;
            i++;
        }
    }, 1000);
}

//simple helper to see if we are in an iframe, there are a lot of those on publisher sites
function inIframe () {
    try {
        return window.self !== window.top;
    }
    catch (e) {
        return true;
    }
}


// this function is used, when you click the toolbar icon to return for you the URL,
// which we previously injected ourselves, if no OADOI it will see if it got a "not on oa" message
// previously (oahdoire == 0) and provide no OA found message, otherwise inactive message.

function getKnownOAUrl(){
    var div = document.getElementById("doicheckmark");
    var oahdoire = document.body.dataset['oahdoire'];
    if(div != null){
        var url = div.dataset.oaurl;
        safari.extension.dispatchMessage("oaURLReturn", {"oaurl" : url});
    }
    else if(oahdoire == 0){
        safari.extension.dispatchMessage("needIntlAlert", {"msgId" : "oahdoire_0"});
        //alert("Open Access Helper could not find a legal open-access version of this article.")
    }
    else{
        safari.extension.dispatchMessage("needIntlAlert", {"msgId" : "oahdoire_1"});
        //alert("Open Access Helper is inactive on this page, as we could not identify a DOI");
    }
    
}

// if oadoi gives back an empty result or not oa result,
// we will run this to see if we might OA on the page
// uses some site specific logic

function alternativeOA(){
    var host = window.location.hostname;
    
    if(host.indexOf("ingentaconnect") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
        // Ingenta Connect
        if (document.querySelectorAll("span.access-icon img[alt='Open Access']").length > 0){
            var onclick = document.querySelectorAll("a.fulltext.pdf")[0].getAttribute('onclick');
            if(onclick != null && onclick != "" && onclick.indexOf("javascript" > -1)){
                var href = onclick.replace("javascript:popup('", "").replace("','downloadWindow','900','800')", "");
                if(href != null && href != ""){
                    var message = new Array();
                    message['url'] = window.location.protocol+'//'+host+href;
                    message['title'] = "Open Access Found on this page: ";
                    oafound(message);
                    onOa();
                }
            }
            else{
                var popup = document.querySelectorAll("a.fulltext.pdf")[0].dataset.popup
                if(popup != null && popup != "" && popup.indexOf("download" > -1)){
                    if(popup != null && popup != ""){
                        var message = new Array();
                        message['url'] = window.location.protocol+'//'+host+popup;
                        message['title'] = "Open Access Found on this page: ";
                        oafound(message);
                        onOa();
                    }
                }
            }
            
        }
    }
    else if(host.indexOf("base-search.net") > -1 && window.location.href.indexOf("/Record/") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
        if (document.querySelectorAll("img.pull-right[alt='Open Access']").length > 0){
            webscraperBadge("a.link-gruen.bold", false)
        }
    }
    else if(host.indexOf("ieeexplore.ieee.org") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
        if (document.querySelectorAll("i.icon-access-open-access").length > 0){
            webscraperBadge("a.doc-actions-link.stats-document-lh-action-downloadPdf_2", false)
        }
    }
    else if(host.indexOf("journals.sagepub.com") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
        if(document.querySelectorAll("img.accessIcon.freeAccess").length > 0){
            webscraperBadge("a[data-item-name=\"download-PDF\"]", true);
        }
        else{
            console.log("Open Access Helper (Safari Extension): We are checking: "+host+" for hybrid journal access");
            if(document.querySelectorAll('img.accessIcon.openAccess').length > 0){
                webscraperBadge("div.pdf-access>a", true)
            }
        }
        
    }
    else if(host.indexOf("academic.oup.com") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
        if(document.querySelectorAll("i.icon-availability_free").length > 0){
            webscraperBadge("a.article-pdfLink", true);
        }
    }
    else if(host.indexOf("bmj.com") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" for hybrid journal access");
        if(document.querySelectorAll("svg.icon-open-access").length > 0){
            var pdf = getMeta("citation_pdf_url")
            if(pdf != "" && pdf.indexOf("http" == 0)){
                successfulAlternativeOAFound(pdf)
            }
        }
        else{
            console.log("Open Access Helper (Safari Extension): no Open Access Found");
        }
    }
    else if(host.indexOf("cambridge.org") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" for hybrid journal access");
        if(document.querySelectorAll("span.entitled").length > 0){
            var pdf = getMeta("citation_pdf_url")
            if(pdf != "" && pdf.indexOf("http" == 0)){
                successfulAlternativeOAFound(pdf)
            }
        }
        else{
            console.log("Open Access Helper (Safari Extension): no Open Access Found");
        }
    }
}

//

function successfulAlternativeOAFound(pdf){
    var message = new Array();
    message['url'] = pdf;
    message['title'] = "Open Access found at: ";
    oafound(message);
    var currentUrl = window.location.href;
    safari.extension.dispatchMessage("compareURL", {"current" : currentUrl, "goto" : message.url});
}


//runRegexOnDoc - inspired by unpaywall.org

function runRegexOnDoc(regEx){
    var m = regEx.exec(document.documentElement.innerHTML);
    if (m && m.length > 1){
       return m[1];
    }
    return false
}

// helper function, checks DOI is valid and then logs to browser console and
// asks Extension Handler to get going

function scrapedDoi(doi){
    if(isDOI(doi)){
        console.log("Open Access Helper (Safari Extension) found this DOI: "+doi)
        var url = encodeURI(location.href)
        safari.extension.dispatchMessage("found", {"doi" : doi, "url" : url});
    }
}

function webscraperBadge(selector, onoa){
    var href = document.querySelectorAll(selector)[0].href;
    if(href != null && href != ""){
        var message = new Array();
        message['url'] = href;
        message['title'] = "Open Access found at: ";
        oafound(message);
        if(onoa){
            onOa("This is the Open Access location!");
        }
    }
}


//the purpose of this function is to let SafariExtensionHandler know what text was selected
//the extensionhandler will then update the context menu item
function handleContextMenu(event) {
    var selectedText =  window.getSelection().toString();
    safari.extension.setContextMenuEventUserInfo(event, { "selectedText": selectedText });
}


function fireOnKeypress(){
    const e = event;
    if (event.target.nodeName.toLowerCase() !== 'input'){
        if (e.altKey && e.ctrlKey && e.keyCode == 79) {
            var selectedText =  window.getSelection().toString();
            var div = document.getElementById("doicheckmark");
            if(selectedText != ""){
                safari.extension.dispatchMessage("searchOA", {"selected" : selectedText});
            }
            else if(div != null){
                var url = div.dataset.oaurl;
                safari.extension.dispatchMessage("oaURLReturn", {"oaurl" : url});
            }
            else{
                //
            }
        }
    }
}


function handleConfirmRequest(msg){
    if(window.confirm(msg)){
        //ask extension to go to user FAQ
        var url = "https://www.otzberg.net/oahelper/userfaq.html";
        safari.extension.dispatchMessage("oaURLReturn", {"oaurl" : url});
    }
}


function evaluateTab(){
    var div = document.getElementById("doicheckmark");
    var badge = ""
    if (div != undefined){
        badge = div.dataset.badge
    }
    if(badge == "!" || badge == "✔"){
        safari.extension.dispatchMessage("badgeUpdate", {"badge" : badge});
    }
    
}
