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
        alternativeOA(event.message.doi, event.message.oab, event.message.doistring);
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
    else if (event.name == "doCoreRecom"){
        coreRecommenderStart(event.message.doistring, event.message.infoString);
    }
    else if (event.name == "recomResults"){
        if(event.message.action == "dismiss"){
            //console.log(event.message.detail);
            dismissCoreRecommender();
        }
        else{
            showRecommendations(event.message.data, event.message.infoString);
        }
    }
}

function findDoi(){
    //console.log("Open Acces Helper: DOI0");
    // we are going to look in meta-tags for the DOI
    var option = ['citation_doi', 'doi', 'dc.doi', 'dc.identifier', 'dc.identifier.doi', 'bepress_citation_doi', 'rft_id', 'dcsext.wt_doi', 'DC.identifier'];
    var doi = [];
    for(i = 0; i < option.length; i++){
        var potentialDoiArray = getMeta(option[i]);

        for(j = 0; j < potentialDoiArray.length; j++){
            var testDoi = potentialDoiArray[j];
            if(testDoi != "" && isDOI(cleanDOI(testDoi))){
                doi.push(cleanDOI(testDoi));
            }
        }
    }
    executeFoundDoi(doi);
}

function executeFoundDoi(doi){

    if(doi[0] != undefined && doi[0] != ""){
        cleanedDOI = cleanDOI(doi[0])
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
    var potentialDoiArray = getMetaScheme('dc.Identifier', 'doi');
    var doi = [];
    for(i = 0; i < potentialDoiArray.length; i++){
        var testDoi = potentialDoiArray[i];
        if(testDoi != "" && isDOI(cleanDOI(testDoi))){
            doi.push(cleanDOI(testDoi));
        }
    }
    
    if(doi[0] != undefined && doi[0] != ""){
        console.log("Open Access Helper (Safari Extension) found this DOI (1): "+doi[0])
        var url = encodeURI(location.href);
        safari.extension.dispatchMessage("found", {"doi" : doi[0], "url" : url});
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
        // this is a Single Page Application and the delay helps catch the DOI
        setTimeout(function (){
          var regex = new RegExp('"doi":"([^"]+)"');
          var doi = runRegexOnDoc(regex);
          if(doi != false){
              scrapedDoi(doi);
          }
          else{
              alternativeOA("n", "n", "-");
          }

        }, 1500);
        
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
            alternativeOA("n", "n", "-");
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
        alternativeOA("n", "n", "-");
    }
}


function getMeta(metaName) {
    // get meta tags and loop through them. Looking for the name attribute and see if it is the metaName
    // we were looking for
    const metas = document.getElementsByTagName('meta');
    var response = []
    
    for (let i = 0; i < metas.length; i++) {
        if (metas[i].getAttribute('name') === metaName) {
            response.push(metas[i].getAttribute('content'));
        }
    }
    return response;
}

function getMetaForAbstract(metaName) {
    // get meta tags and loop through them. Looking for the name attribute and see if it is the metaName
    // we were looking for
    const metas = document.getElementsByTagName('meta');
    
    for (let i = 0; i < metas.length; i++) {
        if (metas[i].getAttribute('name') === metaName) {
            return metas[i].getAttribute('content');
        }
    }
    
    return "0";
}

function getMetaScheme(metaName, scheme){
    // pretty much the same as the other function, but it also double-checks the scheme
    const metas = document.getElementsByTagName('meta');
    var response = []
    for (let i = 0; i < metas.length; i++) {
        if (metas[i].getAttribute('name') === metaName && metas[i].getAttribute('scheme') === scheme) {
            response.push(metas[i].getAttribute('content'));
        }
    }
    
    return response;
}

function getMetaProperty(metaName){
    const metas = document.getElementsByTagName('meta');
    
    for (let i = 0; i < metas.length; i++) {
        if (metas[i].getAttribute('property') === metaName) {
            return metas[i].getAttribute('content');
        }
    }
    
    return "0";
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

    var oaVersion = "";
    if(message.version != ""){
        oaVersion = " - OA Version: "+message.version;
    }
    else{
        message.version = "CORE Discovery";
    }
    
    var div = document.createElement('div');
    div.innerHTML = '<div class="oahelper_doifound" onclick="window.open(\''+message.url+'\')" title="'+message.title+message.url+oaVersion+'"><img id="oahelper_doicheckmark" src="'+src+'" align="left" title="'+message.title+message.url+oaVersion+'" data-oaurl="'+message.url+'" data-badge="!"/><span id="oahelper_oahelpmsg">'+message.version+'</span></div><span id="oahelper_LiveRegion" role="alert" aria-live="assertive" aria-atomic="true"></span>'; // data-oaurl is a gift to ourselves
    div.id = 'oahelper_doifound_outer';
    div.className = 'oahelper_doifound_outer';
    
    if(document.body.parentNode.parentNode != "#document"){
        document.body.appendChild(div);
    }

    console.log("Open Access Helper (Safari Extension) found this Open Access URL ("+message.source+"): "+message.url+oaVersion)
    var currentUrl = window.location.href;
    safari.extension.dispatchMessage("compareURL", {"current" : currentUrl, "goto" : message.url});
    var trackCall = setInterval(function () {
        var div = document.getElementById("oahelper_LiveRegion");
        div.innerHTML = message.title;
        clearInterval(trackCall);
    }, 4000);
}

function requestDocument(oab, doistring){
    
    // find out whether we are supposed to do CORE Recommender at All
    safari.extension.dispatchMessage("doCoreRecom", {"doistring" : doistring});
    
    // here we inject the icon into the page
    
    if(oab == "n"){
        return;
    }
    
    if(oab == "e"){
        console.log("Open Access Helper (Safari Extension): Open Access Button not possible, as there was an error obtaining pub data");
        return;
    }
    
    if(oab == "o"){
        console.log("Open Access Helper (Safari Extension): Open Access Button not possible, as Pub Year > 5 years ago");
        return;
    }
    
    var src = safari.extension.baseURI + "ask.png"; // padlock
    var url = encodeURIComponent(location.href);
    var oabUrl = "https://openaccessbutton.org/request?url="
    var message = "We didn't find a legal Open Access Version, but you could try and request it via Open Access Button";
    
    var div = document.createElement('div');
    div.innerHTML = '<div class="oahelper_doifound" onclick="window.open(\''+oabUrl+url+'\')" title="'+message+'"><img id="oahelper_doicheckmark" src="'+src+'" align="left"  title="'+message+'" data-oaurl="'+oabUrl+url+'" data-badge=""/><span id="oahelper_oahelpmsg">Open Access Button</span></div><span id="oahelper_LiveRegion" role="alert" aria-live="assertive" aria-atomic="true"></span>'; // data-oaurl is a gift to ourselves
    div.id = 'oahelper_doifound_outer';
    div.className = 'oahelper_doifound_outer oahelper_doiblue';
    
    if(document.body.parentNode.parentNode != "#document"){
        document.body.appendChild(div);
    }
    console.log("Open Access Helper (Safari Extension) did not find any Open Access, but you can try to request from Open Access Button ")
    var currentUrl = window.location.href;
    var trackCall = setInterval(function () {
                                var div = document.getElementById("oahelper_LiveRegion");
                                div.innerHTML = message;
                                clearInterval(trackCall);
                                }, 4000);
}


// if on Open Access document, this will turn the injected badge / button green

function onOa(message){
    var div = document.getElementById("oahelper_doifound_outer");
    div.classList.add("oahelper_doigreen");
    var div1 = document.getElementById("oahelper_doicheckmark");
    div1.dataset.badge = "✔"
    var trackCall = setInterval(function () {
        var div = document.getElementById("oahelper_LiveRegion");
        div.innerHTML = message.title;
        clearInterval(trackCall);
    }, 8000);
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
    var div = document.getElementById("oahelper_doicheckmark");
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

function alternativeOA(message, oab, doistring){
    //console.log("OAHelper alternativeOA");
    var host = window.location.hostname;
    var path = window.location.pathname;
    var generator = getMeta('Generator');
    
    if(host.indexOf("ingentaconnect") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
        // Ingenta Connect
        if (document.querySelectorAll("span.access-icon img[alt='Open Access']").length > 0){
            var onclick = document.querySelectorAll("a.fulltext.pdf")[0].getAttribute('onclick');
            if(onclick != null && onclick != "" && onclick.indexOf("javascript" > -1)){
                var href = onclick.replace("javascript:popup('", "").replace("','downloadWindow','900','800')", "");
                if(href != null && href != ""){
                    var url = window.location.protocol+'//'+host+href;
                    successfulAlternativeOAFound(url, "Free Access", true);
                }
                else{
                    console.log("Open Access Helper (Safari Extension): no Open Access Found");
                    requestDocument(oab, doistring);
                }
            }
            else{
                var popup = document.querySelectorAll("a.fulltext.pdf")[0].dataset.popup
                if(popup != null && popup != "" && popup.indexOf("download" > -1)){
                    if(popup != null && popup != ""){
                        var url = window.location.protocol+'//'+host+popup;
                        successfulAlternativeOAFound(url, "Free Access", true);
                    }
                    else{
                        console.log("Open Access Helper (Safari Extension): no Open Access Found");
                        requestDocument(oab, doistring);
                    }
                }
                else{
                    console.log("Open Access Helper (Safari Extension): no Open Access Found");
                    requestDocument(oab, doistring);
                }
            }
            
        }
    }
    else if(host.indexOf("base-search.net") > -1 && window.location.href.indexOf("/Record/") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
        if (document.querySelectorAll("img.pull-right[alt='Open Access']").length > 0){
            webscraperBadge("a.link-gruen.bold", false, oab);
        }
        else{
            console.log("Open Access Helper (Safari Extension): no Open Access Found");
            requestDocument(oab, doistring);
        }
    }
    else if(host.indexOf("ieeexplore.ieee.org") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
        if (document.querySelectorAll("i.icon-access-open-access").length > 0){
            webscraperBadge("a.doc-actions-link.stats-document-lh-action-downloadPdf_2", false, oab);
        }
        else{
            console.log("Open Access Helper (Safari Extension): no Open Access Found");
            requestDocument(oab, doistring);
        }
    }
    else if(host.indexOf("journals.sagepub.com") > -1 && path.indexOf("doi") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
        if(document.querySelectorAll("img.accessIcon.freeAccess").length > 0){
            webscraperBadge("a[data-item-name=\"download-PDF\"]", true, oab);
        }
        else{
            console.log("Open Access Helper (Safari Extension): We are checking: "+host+" for hybrid journal access");
            if(document.querySelectorAll('img.accessIcon.openAccess').length > 0){
                webscraperBadge("div.pdf-access>a", true, oab);
            }
            else{
                console.log("Open Access Helper (Safari Extension): no Open Access Found");
                requestDocument(oab, doistring);
            }
        }
        
    }
    else if(host.indexOf("academic.oup.com") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
        if(document.querySelectorAll("i.icon-availability_free").length > 0){
            webscraperBadge("a.article-pdfLink", true, oab);
        }
        else{
            console.log("Open Access Helper (Safari Extension): no Open Access Found");
            requestDocument(oab, doistring);
        }
    }
    else if(host.indexOf("bmj.com") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" for hybrid journal access");
        if(document.querySelectorAll("svg.icon-open-access").length > 0){
            var pdf = getMeta("citation_pdf_url")
            if(pdf != "" && pdf.indexOf("http" == 0)){
                successfulAlternativeOAFound(pdf, "Open Access", true)
            }
            else{
                console.log("Open Access Helper (Safari Extension): no Open Access Found");
                requestDocument(oab, doistring);
            }
        }
        else{
            console.log("Open Access Helper (Safari Extension): no Open Access Found");
            requestDocument(oab, doistring);
        }
    }
    else if(host.indexOf("cambridge.org") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" for hybrid journal access");
        if(document.querySelectorAll("span.entitled").length > 0){
            var pdf = getMeta("citation_pdf_url")
            if(pdf != "" && pdf.indexOf("http" == 0)){
                successfulAlternativeOAFound(pdf, "Free / Subscription Access", true)
            }
        }
        else{
            console.log("Open Access Helper (Safari Extension): no Open Access Found");
            requestDocument(oab, doistring);
        }
    }
    else if(host.indexOf("onlinelibrary.wiley.com") > -1 && path.indexOf("doi") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" for \"Free Access\"");
        var toCheck = document.querySelectorAll("div.article-citation > div > div.doi-access-container.clearfix > div > div");
        if(toCheck.length > 0 && toCheck[0].innerHTML.indexOf("Free Access")){
            console.log("Open Access Helper (Safari Extension): We found FREE Access");
            var pdf = getMeta("citation_pdf_url");
            successfulAlternativeOAFound(pdf, "Free Access", true);
        }
        else{
            console.log("Open Access Helper (Safari Extension): no Open Access Found");
            if(path.indexOf("doi/pdf") == -1){
                requestDocument(oab, doistring);
            }
            
        }
    }
    else if(host.indexOf("link.springer.com") > -1 && path.indexOf("article") > -1){
        console.log("Open Access Helper (Safari Extension): We are checking: "+host+" for \"Free Access\"");
        var toCheck = document.querySelectorAll("div.download-article");
        if(toCheck.length > 0 && toCheck[0].innerHTML.indexOf("Download") > -1){
            console.log("Open Access Helper (Safari Extension): We found FREE / Subscription Access");
            var pdf = getMeta("citation_pdf_url");
            successfulAlternativeOAFound(pdf, "Free / Subscription Access", true);
        }
        else{
            console.log("Open Access Helper (Safari Extension): no Open Access Found");
            requestDocument(oab, doistring);
        }
    }
    
    else if(generator.length > 0 && generator[0].indexOf('DSpace') > -1){
        console.log("Open Access Helper (Safari Extension): we are on a DSPACE respository - there is a chance the document is available here");
    }
    else if(message != undefined && message == "y"){
        console.log("Open Access Helper (Safari Extension): no Open Access Found");
        requestDocument(oab, doistring);
    }
    else{
        console.log("OAHELPER FALLBACK in alternativeOA")
        requestDocument(oab, doistring);
    }
    
}

//

function successfulAlternativeOAFound(pdf, type = "Open Access", onOa = false){
    var message = new Array();
    message['url'] = pdf;
    message['title'] = type+" found at: ";
    message['version'] = "unknown";
    message['source'] = "Page Analysis";
    oafound(message);
    var currentUrl = window.location.href;
    if(onOa){
        
    }
    else{
      safari.extension.dispatchMessage("compareURL", {"current" : currentUrl, "goto" : message.url});
    }
    
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

function webscraperBadge(selector, onoa, oab){
    var doistring = "-"
    var selected = document.querySelectorAll(selector);
    if(selected.length == 0){
        requestDocument(oab, doistring);
        return;
    }
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
    else{
        requestDocument(oab, doistring);
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
            var div = document.getElementById("oahelper_doicheckmark");
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
    var div = document.getElementById("oahelper_doicheckmark");
    var badge = ""
    if (div != undefined){
        badge = div.dataset.badge
    }
    if(badge == "!" || badge == "✔"){
        safari.extension.dispatchMessage("badgeUpdate", {"badge" : badge});
    }
    
}

// Core Recommender Related Functions

function coreRecommenderStart(doistring, infoString){
    if(isDOI(doistring)){
        var doi = doistring;
    }
    else{
        return;
    }
    
    var currentUrl = document.URL;
    var docTitle = findTitle();
    var abstract = findAbstract();

    if(doi == "" && docTitle == "0" && abstract == "0"){
        return
    }
    
    console.log("DOI FOR RECOMMENDATION: "+doi);
    console.log("abstract length: "+abstract.length)
    
    var src = safari.extension.baseURI + "recom.png"; // padlock
    var message = "We didn't find a legal Open Access Version, but you could try and review some CORE Open Access Recommendations instead";
    
    var div = document.createElement('div');
    div.innerHTML = '<div class="oahelper_corerecom" title="'+message+'"><img id="oahelper_doicheckmark1" src="'+src+'" align="left"  title="'+message+'" data-doi="'+doi+'" data-badge=""/><span id="oahelper_oahelpmsg">CORE Recommender</span></div>'; // data-oaurl is a gift to ourselves
    div.id = 'oahelper_corerecom_outer';
    div.className = 'oahelper_corerecom_outer oahelper_corecolor';
    
    if(document.body.parentNode.parentNode != "#document"){
        document.body.appendChild(div);
    }
    const element = document.getElementById("oahelper_corerecom_outer");
    //element.addEventListener("click", doCORERecom, false);
    addRecommenderClickHandler(element, infoString);
    console.log("Open Access Helper (Safari Extension) did not find any Open Access, but you can review some CORE Open Access Recommendations")
    
}

function addRecommenderClickHandler(element, infoString) {
    element.addEventListener('click', function(e) {
        doCORERecom(infoString);
    }, false);
}

function findAbstract(){
    var locations = ['DC.description', 'dc.Description', 'DCTERMS.abstract', 'eprints.abstract', 'description', 'Description'];
    var abstract = "0";
    
    for(i = 0; i < locations.length; i++){
        if(abstract == "0"){
           abstract = getMetaForAbstract(locations[i]);
        }
    }
    var ogLocation = ['og:description'];
    for(j = 0; j < ogLocation.length; j++){
        if(abstract == "0"){
           abstract = getMetaProperty(ogLocation[j]);
        }
    }
    if(abstract.length > 2000){
        abstract = abstract.substring(0, 2000);
    }
    return abstract;
}

function findTitle(){
    var locations = ['citation_title'];
    var title = "0";
    
    for(i = 0; i < locations.length; i++){
        if(title == "0"){
           title = getMetaForAbstract(locations[i]);
        }
    }
    if(title == 0){
        title = document.title;
    }
    
    return title
    
}


function doCORERecom(infoString){

    console.log("doCORERecom");
    
    var element = document.getElementById("oahelper_doicheckmark1");
   
    var doi = element.dataset.doi;
    var currentUrl = document.URL;
    var docTitle = findTitle();
    var abstract = findAbstract();
        
    //remove button
    var element1 = document.getElementById("oahelper_corerecom_outer");
    element1.parentNode.removeChild(element1);
    
    var imgSrc = safari.extension.baseURI + "loader.gif";
    var logoSrc = safari.extension.baseURI + "core_logo.svg";
    
    //add sidebar
    var div = document.createElement('div');
    div.innerHTML = '<div id="oahelper_corerecommendations" ><div id="oahelper_corerecom_intro"><img src="'+logoSrc+'" id="oahelper_core_logo"> Recommender <div id="oahelper_core_x" title="close">X close</div></div><div id="oahelper_correcom_intro2">'+infoString+'</div><div id="oahelper_spinner"><img src="'+imgSrc+'"></div></div>'; // data-oaurl is a gift to ourselves
    div.id = 'oahelper_corerecommender_outer';
    div.className = 'oahelper_corerecommender_outer';
    
    if(document.body.parentNode.parentNode != "#document"){
        document.body.appendChild(div);
    }
    
    var element2 = document.getElementById("oahelper_core_x");
    element2.addEventListener("click", dismissCoreRecommendations, false);
    
    setTimeout(function () {
        var element3 = document.getElementById("oahelper_corerecommender_outer");
        element3.classList.remove("oahelper_animate_out");
        element3.classList.add("oahelper_animate_in")
    } , 200);
    
    
    safari.extension.dispatchMessage("requestRecommendation", {"doi" : doi, "currentUrl" : currentUrl, "docTitle" : docTitle, "abstract" : abstract});
}

function dismissCoreRecommender(){
    console.log("Open Access Helper (Safari Extension): There were no recommendations, removing info")
    
    var element = document.getElementById("oahelper_spinner");
    element.parentNode.removeChild(element)
    
    var element = document.getElementById("oahelper_correcom_intro2");
    element.parentNode.removeChild(element)
    
    var myRecomElement = document.getElementById("oahelper_corerecommendations");
    
    var div = document.createElement('div');
    div.className = "oahelper_recommendation";
    div.innerHTML = '<p class="oahelper_recommendation_p">We were hopeful, but there were no recommendations :( This will automatically dismiss in a few seconds.</p>';
    myRecomElement.appendChild(div);
    
    setTimeout(function () {
               dismissCoreRecommendations();
    }, 5500);
}

function showRecommendations(data, infoString){
    var element = document.getElementById("oahelper_spinner");
    element.parentNode.removeChild(element)
    
    var intro = document.getElementById("oahelper_correcom_intro2");
    intro.innerHTML = infoString;
    
    var myRecomElement = document.getElementById("oahelper_corerecommendations");
    var obj = JSON.parse(data)
    for(i=0; i<obj.length; i++){
        var year = ""
        if(obj[i].year != ""){
            year = "("+obj[i].year+") ";
        }
        var div = document.createElement('div');
        div.className = "oahelper_recommendation";
        div.innerHTML = '<p class="oahelper_recommendation_p"><a href="'+obj[i].link+'" target="_blank" class="oahelper_recommendation_a">'+obj[i].title+'</a><br>'+year+obj[i].author+'</p>';
        myRecomElement.appendChild(div);
    }
    
}

function dismissCoreRecommendations(){
    var element = document.getElementById("oahelper_corerecommender_outer");
    element.parentNode.removeChild(element)
}
