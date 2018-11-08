document.addEventListener("DOMContentLoaded", function(event) {
    //check if we are in an iframe, if so do nothing, otherwise go and find yourself a DOI
    if(!inIframe()){
        findDoi();
    }
                          
});


if(!inIframe()){
    // Listens for messages sent from the app extension's Swift code.
    safari.self.addEventListener("message", messageHandler);
}

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
    
}

function findDoi(){
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
        findDoi1();
    }
    
}

function findDoi1(){
    var doi = getMetaScheme('dc.Identifier', 'doi');
    if(doi != ""){
        console.log("Open Access Helper (Safari Extension) found this DOI: "+doi)
        safari.extension.dispatchMessage("found", {"doi" : doi});
    }
    else{
        findDoi2();
    }
}

function findDoi2(){
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
        safari.extension.dispatchMessage("notfound", {"doi" : ""});
    }
}

function getMeta(metaName) {
    const metas = document.getElementsByTagName('meta');
    
    for (let i = 0; i < metas.length; i++) {
        if (metas[i].getAttribute('name') === metaName) {
            return metas[i].getAttribute('content');
        }
    }
    
    return '';
}

function getMetaScheme(metaName, scheme){
    const metas = document.getElementsByTagName('meta');
    
    for (let i = 0; i < metas.length; i++) {
        if (metas[i].getAttribute('name') === metaName && metas[i].getAttribute('scheme') === scheme) {
            return metas[i].getAttribute('content');
        }
    }
    
    return '';
}

function getFromSelector(selector){
    const elements = document.querySelectorAll(selector);
    
    for (let i = 0; i < elements.length; i++) {
        if(isDOI(elements[i].innerHTML)){
            return elements[i].innerHTML
        }
    }
    
    return '';
}

function cleanDOI(doi){
    var clean = ['info:doi/'];
    
    for(let i = 0; i < clean.length; i++){
        doi = doi.replace(clean[i], '');
    }
    
    return doi;
}

function isDOI(doi){
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

    var src = safari.extension.baseURI + "sec30.png";

    var div = document.createElement('div');
    div.innerHTML = '<div class="doifound" onclick="window.open(\''+message.url+'\')" title="Open Access Version Found! '+message.url+'"><img id="doicheckmark" src="'+src+'" title="Open Access Version Found! '+message.url+'" data-oaurl="'+message.url+'"/></div>';
    div.id = 'doifound_outer'
    div.className = 'doifound_outer'
    
    if(document.body.parentNode.parentNode != "#document"){
        document.body.appendChild(div);
    }
    console.log("Open Access Helper (Safari Extension) found this Open Access URL: "+message.url)
    var currentUrl = window.location.href;
    safari.extension.dispatchMessage("compareURL", {"current" : currentUrl, "goto" : message.url});
    
}

function onOa(){
    var div = document.getElementById("doifound_outer");
    div.classList.add("doiorange");
}


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

//simpe helper to see if we are in an iframe,, there are a lot of those on publisher sites
function inIframe () {
    try {
        return window.self !== window.top;
    }
    catch (e) {
        return true;
    }
}

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
