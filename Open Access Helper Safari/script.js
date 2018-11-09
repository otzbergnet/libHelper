document.addEventListener("DOMContentLoaded", function(event) {
    //check if we are in an iframe, if so do nothing, otherwise go and find yourself a DOI

    if(!inIframe()){
        findDoi();
    }
                          
});


// double checking that we are not in an iFrame

if(!inIframe()){
    // Listens for messages sent from the app extension's Swift code.
    safari.self.addEventListener("message", messageHandler);
}


// handles the requests from the SafariExtensionHandler
function messageHandler(event){
    if (event.name === "doi"){
        findDoi();
    }
    else if (event.name === "url"){
        currentUrl();
    }
    else if (event.name === "oafound"){
        oafound(event.message);
    }
    else if (event.name === "onoa"){
        onOa();
    }
    else if (event.name === "printPls"){
        console.log(event.message);
    }
    else if (event.name == "getOAUrl"){
        getKnownOAUrl();
    }
    else if (event.name == "notoadoi"){
        alternativeOA();
    }
    
}

function findDoi(){
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
        cleanDOI = cleanDOI(doi)
        console.log("Open Access Helper (Safari Extension) found this DOI: "+cleanDOI)
        safari.extension.dispatchMessage("found", {"doi" : doi});
    }
    else{
        // didn't find a DOI yet, so let's look in another place
        findDoi1();
    }
    
}

function findDoi1(){
    
    //in this case, we are looking for both meta-tag and its scheme
    var doi = getMetaScheme('dc.Identifier', 'doi');
    if(doi != ""){
        console.log("Open Access Helper (Safari Extension) found this DOI: "+doi)
        safari.extension.dispatchMessage("found", {"doi" : doi});
    }
    else{
        // didn't find a DOI yet, let's look in yet another place
        findDoi2();
    }
}

function findDoi2(){
    // this is a place for more complex fallbacks, where we can provide additional "CSS-Selectors" to find
    // a DOI
    var selectors = ['a[ref=\"aid_type=doi\"]'];
    var doi = ""
    for(i = 0; i < selectors.length; i++){
        doi = getFromSelector(selectors[i]);
        if(doi != ""){
            break;
        }
    }
    if(doi != ""){
        console.log("Open Access Helper (Safari Extension) found this DOI: "+doi)
        safari.extension.dispatchMessage("found", {"doi" : doi});
    }
    else{
        // we are ready to give up here and send a notfound message, so that we can deactivate the icon
        safari.extension.dispatchMessage("notfound", {"doi" : ""});
        // however giving up is for losers, so we'll try a few more
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
    // allow for more complex CSS selectors, these are likely more "dangerous"
    const elements = document.querySelectorAll(selector);
    
    for (let i = 0; i < elements.length; i++) {
        // make sure we test what we find to be a proper DOI
        if(isDOI(elements[i].innerHTML)){
            return elements[i].innerHTML
        }
    }
    
    return '';
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
    
    // these regular expressions were recommended by CrossRef in a blog
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
    div.innerHTML = '<div class="doifound" onclick="window.open(\''+message.url+'\')" title="Open Access Version Found! '+message.url+'"><img id="doicheckmark" src="'+src+'" title="Open Access Version Found! '+message.url+'" data-oaurl="'+message.url+'"/></div>'; // data-oaurl is a gift to ourselves
    div.id = 'doifound_outer'
    div.className = 'doifound_outer'
    
    if(document.body.parentNode.parentNode != "#document"){
        document.body.appendChild(div);
    }
    console.log("Open Access Helper (Safari Extension) found this Open Access URL: "+message.url)
    var currentUrl = window.location.href;
    safari.extension.dispatchMessage("compareURL", {"current" : currentUrl, "goto" : message.url});
    
}

// if on Open Access document, this will turn the imported badge green

function onOa(){
    var div = document.getElementById("doifound_outer");
    div.classList.add("doigreen");
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
// which we previously injected ourselves

function getKnownOAUrl(){
    var div = document.getElementById("doicheckmark");
    if(div != null){
        var url = div.dataset.oaurl;
        safari.extension.dispatchMessage("oaURLReturn", {"oaurl" : url});
    }
    else{
        alert("Open Access Helper is inactive on this page, as no DOI / Digital Object Identifier is available");
    }
    
}

// if oadoi gives back an empty result or not oa result,
// we will run this to see if we might OA on the page
// uses some site specific logic

function alternativeOA(){
    var host = window.location.hostname;
    
    if(host.indexOf("ingentaconnect") > -1){
        // Ingenta Connect
        if (document.querySelectorAll("span.access-icon img[alt='Open Access']").length > 0){
            var onclick = document.querySelectorAll("a.fulltext.pdf")[0].getAttribute('onclick');
            var href = onclick.replace("javascript:popup('", "").replace("','downloadWindow','900','800')", "");
            if(href != null && href != ""){
                var message = new Array();
                message['url'] = window.location.protocol+'//'+host+href;
                oafound(message);
                onOa();
            }
        }
    }
    else if(host.indexOf("ieeexplore.ieee.org") > -1){
        // IEEE
        var regex = new RegExp('"doi":"([^"]+)"');
        var doi = runRegexOnDoc(regex);
        
        scrapedDoi(doi);
        
    }
    else if(host.indexOf("nber.org") > -1){
        //National Bureau of Economic Research
        var regex = new RegExp('Document Object Identifier \\(DOI\\): (10.*?)<\\/p>');
        var doi = runRegexOnDoc(regex);
        
        scrapedDoi(doi);
        
    }
    
}



//runRegexOnDoc - inspired by unpywall.org

function runRegexOnDoc(regEx){
    var m = regEx.exec(document.documentElement.innerHTML);
    if (m && m.length > 1){
       return m[1];
    }
    return false
}

function scrapedDoi(doi){
    if(isDOI(doi)){
        console.log("Open Access Helper (Safari Extension) found this DOI: "+doi)
        safari.extension.dispatchMessage("found", {"doi" : doi});
    }
}
