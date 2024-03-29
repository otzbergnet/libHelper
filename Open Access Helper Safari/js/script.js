var oah_loaded = 0;
var oah_processedSinglePageApplication = false;
var spaUrl = location.href;
var configuration = [];


var preprintServers = ['arxiv.org', 'biorxiv.org', 'osf.io', 'engrxiv.org', 'psyarxiv.com', 'paleorxiv.org', 'eartharxiv.org', 'edarxiv.org', 'arabixiv.org', 'indiarxiv.org', 'biohackrxiv.org', 'ecoevorxiv.org', 'ecsarxiv.org', 'frenxiv.org', 'mediarxiv.org', 'thesiscommons.org'];

document.addEventListener("DOMContentLoaded", function(event) {
    //check if we are in an iframe, if so do nothing, otherwise go and find yourself a DOI

    if(!inIframe() && oah_loaded == 0){
        oah_loaded++;
        findDoi();
    }
                          
});

// double checking that we are not in an iFrame

if(!inIframe()){
    // Listens for messages sent from the app extension's Swift code.
    safari.self.addEventListener("message", messageHandler);
    document.addEventListener("contextmenu", handleContextMenu, false);
    document.addEventListener("keydown", fireOnKeypress, false);
}

if(window.location.hostname == "gettheresearch.org" || onSupportedDomain('psycnet.apa.org')){
    document.addEventListener('click', ()=>{
        requestAnimationFrame(()=>{
            if(spaUrl !== location.href){
                oah_processedSinglePageApplication = false;
                removeMyself()
                findDoi3();
            }
            else if(onSupportedDomain('psycnet.apa.org')){
                    //moving from search results to first result never triggered the URL change
                    doConsoleLog("OAHELPER: I am on psycnet");
                    setTimeout(function () {
                        doPsycNet();
                    },1500);
            }
            spaUrl = location.href;
        });
    }, true);
}

//support gettheresearch SPA
function removeMyself(){
    var elementRecom = document.getElementById('oahelper_corerecom_outer');
    if(elementRecom != null){
        elementRecom.parentNode.removeChild(elementRecom);
    }
    var element = document.getElementById('oahelper_doifound_outer');
    if(element != null){
      element.parentNode.removeChild(element);
      safari.extension.dispatchMessage("notfound", {"doi" : ""});
    }
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
        document.body.dataset.oahdoire = "1";
        oafound(event.message);
    }
    else if (event.name === "onoa"){
        document.body.dataset.oahdoire = "2";
        onOa(event.message);
    }
    else if (event.name === "printPls"){
        doConsoleLog(event.message);
    }
    else if (event.name == "getOAUrl"){
        getKnownOAUrl();
    }
    else if (event.name == "notoadoi"){
        document.body.dataset.oahdoire = "0";
        //let's put some stuff in sessionStorage
        window.sessionStorage.setItem('ill', event.message.ill);
        window.sessionStorage.setItem('illUrl', event.message.illUrl);
        window.sessionStorage.setItem('illLabel', event.message.illLabel);
        alternativeOA(event.message.doi, event.message.oab, event.message.doistring);
    }
    else if (event.name == "showAlert"){
        if(event.message.ezproxy != ""){
            handleEzProxy(event.message.ezproxy);
        }
        else if(event.message.type == "alert"){
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
        coreRecommenderStart(event.message.doistring, event.message.infoString, event.message.closeLabel);
    }
    else if (event.name == "recomResults"){
        if(event.message.action == "dismiss"){
            //doConsoleLog(event.message.detail);
            dismissCoreRecommender();
        }
        else{
            showRecommendations(event.message.data, event.message.infoString);
        }
    }
    else if (event.name == "addProxy"){
        handleEzProxy(event.message.ezproxy);
    }
    else if (event.name == "removeProxy"){
        var url = window.location.href;
        var prefix = event.message.ezproxy;
        var newUrl = url.replace(prefix, "");
        window.location.href = newUrl;
    }
    else if(event.name == "opencitation_count"){
        var count = event.message.citation_count;
        var doi =   event.message.doi;
        addCitationCount(count,doi);
    }
    else if(event.name == "consolelog_configuration"){
        configuration['consolelog'] = event.message.consolelog;
    }
    else if(event.name == "getCurrentState"){
        let popupAnswer = getPopupAnswer();
        safari.extension.dispatchMessage("currentState", {
            "oaurl": popupAnswer.oaurl,
            "oastatus": popupAnswer.oastatus,
            "citationcount": popupAnswer.citationcount,
            "citationurl": popupAnswer.citationurl,
            "currenturl": popupAnswer.currenturl,
            "isIll": popupAnswer.isIll,
            "doi": popupAnswer.doi}
        );
    }
    else if(event.name == "hideBadge"){
        hideBadgeRequest();
    }
}

function findDoi(){
    safari.extension.dispatchMessage("getconsolelog");
    
    //doConsoleLog("Open Acces Helper: DOI0");
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
        doConsoleLog("Open Access Helper (Safari Extension) found this DOI (0): "+cleanedDOI);
        var url = encodeURI(location.href);
        safari.extension.dispatchMessage("found", {"doi" : cleanedDOI, "url" : url});
    }
    else{
        // didn't find a DOI yet, so let's look in another place
        findDoi1();
    }
}

function findDoi1(){
    //doConsoleLog("Open Acces Helper: DOI1");
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
        doConsoleLog("Open Access Helper (Safari Extension) found this DOI (1): "+doi[0]);
        var url = encodeURI(location.href);
        safari.extension.dispatchMessage("found", {"doi" : doi[0], "url" : url});
    }
    else{
        // didn't find a DOI yet, let's look in yet another place
        findDoi2();
    }
}

function findDoi2(){
    //doConsoleLog("Open Acces Helper: DOI2");
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
        doConsoleLog("Open Access Helper (Safari Extension) found this DOI (2): "+doi);
        var url = encodeURI(location.href);
        safari.extension.dispatchMessage("found", {"doi" : doi, "url" : url});
    }
    else{
        // we are ready to give up here, but not quite
        findDoi3();
    }
}

function findDoi3(){
    //doConsoleLog("Open Acces Helper: DOI3");
    // this handled Research Gate or others that use meta property
    var selectors = ['citation_doi', 'doi', 'dc.doi', 'dc.identifier', 'dc.identifier.doi', 'bepress_citation_doi', 'rft_id', 'dcsext.wt_doi', 'DC.identifier'];
    var doi = ""
    for(i = 0; i < selectors.length; i++){
        doi = getMetaProperty(selectors[i]);
        if(doi != 0){
            break;
        }
    }
    if(doi != 0){
        doConsoleLog("Open Access Helper (Safari Extension) found this DOI (3): "+doi);
        var url = encodeURI(location.href);
        safari.extension.dispatchMessage("found", {"doi" : doi, "url" : url});
    }
    else{
        // we are ready to give up here, but not quite
        findDoi4();
    }
}

function findDoi4(){
    //doConsoleLog("Open Acces Helper: DOI3");
    // if we cannot work through specific selectors, a more general scraping approach might be neeeded
    // to avoid doing this on every page, we specify the pages we support
    
    var host = window.location.hostname;
    if(onSupportedDomain("ieeexplore.ieee.org")){
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
    else if(onSupportedDomain("nber.org")){
        //National Bureau of Economic Research
        var regex = new RegExp('Document Object Identifier \\(DOI\\): (10.*?)<\\/p>');
        var doi = runRegexOnDoc(regex);
        
        scrapedDoi(doi);
        
    }
    else if(onSupportedDomain("base-search.net")){
        // BASE SEARCH - for detail view, really quite superflous, but I like base
        if (document.querySelectorAll("a.link-orange[href^=\"https://doi.org/\"]").length > 0){
            var doi = document.querySelectorAll("a.link-orange[href^=\"https://doi.org/\"]")[0].href.replace('https://doi.org/','').replace('http://doi.org/','');
            scrapedDoi(doi);
        }
        else{
            alternativeOA("n", "n", "-");
        }
    }
    else if(onSupportedDomain("gettheresearch.org")){
        doConsoleLog("Open Access Helper (Safari Extension) - support for gettheresearch.org is experimental");
        // GetTheResearch.org- for detail view, really quite superflous, but I like base
        if(window.location.search.indexOf("zoom=") > -1){
            var potentialDoi = getQueryVariable("zoom");
            scrapedDoi(potentialDoi);
        }
    }
    else if(onSupportedDomain("psycnet.apa.org")){
        doConsoleLog("Open Access Helper (Safari Extension) - support for psycnet.apa.org is experimental");
        
        if(document.querySelectorAll(".citation-text>a").length > 0){
            var doiElements = document.querySelectorAll(".citation-text>a");
            var potentialDoi = doiElements[0];
            potentialDoi = potentialDoi.replace('https://doi.org/', '');
            scrapedDoi(potentialDoi);
        }
        else{
            doPsycNet();
        }
    }
    else if(onSupportedDomain("proquest.com")){
        doConsoleLog("Open Access Helper (Safari Extension) - support for proquest.com is experimental");
        if(document.querySelectorAll(".abstract_Text").length > 0){
            var doiElements = document.querySelectorAll(".abstract_Text");
            var potentialDoi = doiElements[0];
            var regex = new RegExp('DOI:(10\..*)');
            var doi = runRegexOnText(potentialDoi.textContent, regex);
            //doConsoleLog(doi);
            scrapedDoi(doi);
        }
    }
    else if(onSupportedDomain("ebscohost.com") && document.location.href.indexOf("/detail") > -1){
        doConsoleLog("Open Access Helper (Safari Extension) - support for ebscohost.com is experimental");
        const fullTextIndicators = ['pdf-ft', 'html-ft', 'html-ftwg'];
        let isFullText = false;
        fullTextIndicators.forEach(function(item){
            let element = document.getElementsByClassName(item);
            if(element.length > 0){
                isFullText = true;
            }
        });
        
        
        if(document.getElementsByTagName("dd").length > 0){
            var doiElements = document.getElementsByTagName("dd");
            [...doiElements].forEach(function(element){
                if(element.textContent.indexOf("10.") == 0 && isDOI(element.textContent)){
                    if(isFullText){
                        doConsoleLog("Open Access Helper (Safari Extension) - This document is offered in full-text at this location (EBSCOhost)");
                        if (isDOI(element.textContent)) {
                            safari.extension.dispatchMessage("request_citations", {"doi" : element.textContent});
                        }
                    }
                    else{
                        scrapedDoi(element.textContent);
                    }
                }
            });
        }
    }
    else if(onSupportedDomain("dl.acm.org") && document.location.href.indexOf("/doi/") > -1){
        doConsoleLog("Open Access Helper (Safari Extension) - support for dl.acm.org is experimental");
        var urlParts = document.location.href.split("/doi/");
        if(isDOI(urlParts[1])){
            scrapedDoi(urlParts[1]);
        }
    }
    else{
        //doConsoleLog("Open Acces Helper: Failed on DOI3");
        // we are ready to give up here and send a notfound message, so that we can deactivate the icon
        safari.extension.dispatchMessage("notfound", {"doi" : ""});
        // however we'll continue look at the alternativeOA Webscraping methods
        alternativeOA("n", "n", "-");
    }
}

function onSupportedDomain(domain){
  const host = window.location.hostname;
  if(host.indexOf(domain) > -1){
    return true;
  }
  const proxiedDomain = domain.replaceAll('.', '-')+'.';
  if(host.indexOf(proxiedDomain) > -1){
    return true;
  }
  return false;
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
    
    var src = safari.extension.baseURI + "oahelper_white.svg"; // padlock

    var oaVersion = "";
    if(message.version != ""){
        oaVersion = " - OA Version: "+message.version;
    }
    else{
        message.version = "CORE Discovery";
    }
    var div = document.createElement('div');
    div.innerHTML = '<div class="oahelper_doifound" onclick="window.open(\''+message.url+'\')" title="'+message.title+oaVersion+'"><img id="oahelper_doicheckmark" src="'+src+'" align="left" title="'+message.title+oaVersion+'" data-oaurl="'+message.url+'" data-badge="!" data-doi="'+message.doi+'"/><span id="oahelper_oahelpmsg">'+message.version+'</span></div><span id="oahelper_LiveRegion" role="alert" aria-live="assertive" aria-atomic="true"></span>'; // data-oaurl is a gift to ourselves
    div.id = 'oahelper_doifound_outer';
    div.className = 'oahelper_doifound_outer';
    
    if(document.body.parentNode.parentNode != "#document"){
        document.body.appendChild(div);
    }

    doConsoleLog("Open Access Helper (Safari Extension) found this Open Access URL ("+message.source+"): "+message.url+oaVersion);
    var currentUrl = window.location.href;
    safari.extension.dispatchMessage("compareURL", {"current" : currentUrl, "goto" : message.url});
    
    doOaHelperLiveRegion(message.title);
    
}

function requestDocument(oab, doistring){
    var isPreprint = false;
      preprintServers.forEach((server) => {
        if (document.location.href.indexOf(server) > -1) {
          isPreprint = true;
        }
      });
      // here we inject the icon into the page

      if (isPreprint) {
          handlePreprintSites();
          return;
      }
    
    // find out whether we are supposed to do CORE Recommender at All
    safari.extension.dispatchMessage("doCoreRecom", {"doistring" : doistring});
    
    // let's get data out of sessionStorage
    var ill = window.sessionStorage.getItem('ill');
    var illUrl = window.sessionStorage.getItem('illUrl');
    var illLabel = window.sessionStorage.getItem('illLabel');
    
    // here we inject the icon into the page
    if(oab == "n" && ill == "n"){
        return;
    }
    
    if(oab == "e" && ill == "n"){
        doConsoleLog("Open Access Helper (Safari Extension): Open Access Button not possible, as there was an error obtaining pub data");
        return;
    }
    
    if(oab == "o" && ill == "n"){
        doConsoleLog("Open Access Helper (Safari Extension): Open Access Button not possible, as Pub Year > 5 years ago");
        return;
    }
    
    if(doistring == "" || doistring == "-"){
        return;
    }
    
    var src = safari.extension.baseURI + "ask.svg"; // padlock
    var url = encodeURIComponent(location.href);
    var oabUrl = "https://openaccessbutton.org/request?url="
    var message = "We didn't find a legal Open Access Version, but you could try and request it via Open Access Button";
    var serviceName = "Open Access Button";
    var badge = "oab";
    
    if(ill == "y"){
        url = "";
        oabUrl = illUrl+doistring;
        message = "We didn't find a legal Open Access Version, but you could try and request it from your library";
        serviceName = illLabel;
        badge = "ill";
    }
    // clean up session storage
    window.sessionStorage.clear();
    
    var div = document.createElement('div');
    div.innerHTML = '<div class="oahelper_doifound" onclick="window.open(\''+oabUrl+url+'\')" title="'+message+'"><img id="oahelper_doicheckmark" src="'+src+'" align="left"  title="'+message+'" data-oaurl="'+oabUrl+url+'" data-badge="'+badge+'" data-doi="'+doistring+'"/><span id="oahelper_oahelpmsg">'+serviceName+'</span></div><span id="oahelper_LiveRegion" role="alert" aria-live="assertive" aria-atomic="true"></span>'; // data-oaurl is a gift to ourselves
    div.id = 'oahelper_doifound_outer';
    div.className = 'oahelper_doifound_outer oahelper_doiblue';
    
    if(document.body.parentNode.parentNode != "#document"){
        document.body.appendChild(div);
    }
    doConsoleLog("Open Access Helper (Safari Extension) did not find any Open Access, but you can try to request from "+serviceName);
    var currentUrl = window.location.href;
    
    doOaHelperLiveRegion(message.title);
}


// if on Open Access document, this will turn the injected badge / button green

function onOa(message){
    var div = document.getElementById("oahelper_doifound_outer");
    div.classList.add("oahelper_doigreen");
    var div1 = document.getElementById("oahelper_doicheckmark");
    div1.dataset.badge = "✔"
    
    doOaHelperLiveRegion(message.title);
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
    //doConsoleLog("OAHelper alternativeOA");
    var host = window.location.hostname;
    var path = window.location.pathname;
    var generator = getMeta('Generator');
    
    if(host.indexOf("ingentaconnect") > -1){
        doIngentaConnect(oab, doistring, host);
    }
    else if(host.indexOf("base-search.net") > -1 && window.location.href.indexOf("/Record/") > -1){
        doBaseSearch(oab, doistring, host);
    }
    else if(host.indexOf("ieeexplore.ieee.org") > -1){
        doIEEExplore(oab, doistring, host);
    }
    else if(host.indexOf("journals.sagepub.com") > -1 && path.indexOf("doi") > -1){
        doSagePub(oab, doistring, host);
    }
    else if(host.indexOf("academic.oup.com") > -1){
        doOup(oab, doistring, host);
    }
    else if(host.indexOf("bmj.com") > -1){
        doBmj(oab, doistring, host);
    }
    else if(host.indexOf("cambridge.org") > -1){
        doCambridge(oab, doistring, host);
    }
    else if(host.indexOf("onlinelibrary.wiley.com") > -1 && path.indexOf("doi") > -1){
        doWiley(oab, doistring, host);
    }
    else if(host.indexOf("link.springer.com") > -1 && path.indexOf("article") > -1){
        doSpringerLink(oab, doistring, host);
    }
    else if(generator.length > 0 && generator[0].indexOf('DSpace') > -1){
        doConsoleLog("Open Access Helper (Safari Extension): we are on a DSPACE respository - there is a chance the document is available here");
    }
    else if (host.indexOf('agrirxiv.org') > -1) {
      setTimeout(doOSFArxiv, 2500);
    }
    else if (!oah_processedSinglePageApplication && preprintServers.includes(document.location.hostname)) {
      oah_processedSinglePageApplication = true;
      setTimeout(findDoi, 2500);
    }
    else if (host.indexOf('tandfonline.com') > -1 && path.indexOf('/doi/full/')){
        doTandFOnline(oab, doistring, host);
    }
    else if(message != undefined && message == "y"){
        doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
        requestDocument(oab, doistring);
    }
    else{
        requestDocument(oab, doistring);
    }
    
}

//

function successfulAlternativeOAFound(pdf, type = "Open Access", onOaTest = false, doistring){
    var message = new Array();
    message['url'] = pdf;
    message['title'] = type+" found at: ";
    message['version'] = type+" (*)";
    message['source'] = "Page Analysis";
    message['doi'] = doistring;
    oafound(message);
    var currentUrl = window.location.href;
    if(onOaTest){
        onOa(message);
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

function runRegexOnText(text, regEx){
    doConsoleLog(text)
    var m = regEx.exec(text);
    if (m && m.length > 1){
        doConsoleLog(m)
       return m[1];
    }
    return false
}

// helper function, checks DOI is valid and then logs to browser console and
// asks Extension Handler to get going

function scrapedDoi(doi){
    if(isDOI(doi)){
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
        message['version'] = "Free Access (*)";
        message['doi'] = "x";
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
//            else if(div != null){
//                var url = div.dataset.oaurl;
//                safari.extension.dispatchMessage("oaURLReturn", {"oaurl" : url});
//            }
            else{
//                safari.extension.dispatchMessage("oaURLReturn", {"oaurl" : "pleaseproxy"});
                safari.extension.dispatchMessage("popoverAction");
            }
        }
    }
}


function handleConfirmRequest(msg){
    if(window.confirm(msg)){
        //ask extension to go to user FAQ
        var url = "https://www.oahelper.org/user-faq/";
        safari.extension.dispatchMessage("oaURLReturn", {"oaurl" : url});
    }
}



function handleEzProxy(ezproxy){
    var currentUrl = window.location.href;
    if(window.location.href.indexOf(ezproxy) > -1){
        var url = currentUrl.replace(ezproxy, "");
    }
    else{
        var url = ezproxy+currentUrl;
    }
    window.location.href = url;
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

function coreRecommenderStart(doistring, infoString, closeLabel){
    handlePreprintSites();
    
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
    
    var src = safari.extension.baseURI + "recom.svg"; // padlock
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
    addRecommenderClickHandler(element, infoString, closeLabel);
    doConsoleLog("Open Access Helper (Safari Extension) did not find any Open Access, but you can review some CORE Open Access Recommendations");
    
}

function addRecommenderClickHandler(element, infoString, closeLabel) {
    element.addEventListener('click', function(e) {
        doCORERecom(infoString, closeLabel);
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


function doCORERecom(infoString, closeLabel){

    doConsoleLog("doCORERecom");
    
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
    
    //add sidebar // TO DO: the X close needs to be translatable
    var div = document.createElement('div');
    div.innerHTML = '<div id="oahelper_corerecommendations" ><div id="oahelper_corerecom_intro"><img src="'+logoSrc+'" id="oahelper_core_logo"> Recommender <div id="oahelper_core_x" title="close">X '+closeLabel+'</div></div><div id="oahelper_correcom_intro2">'+infoString+'</div><div id="oahelper_spinner"><img src="'+imgSrc+'"></div></div>'; // data-oaurl is a gift to ourselves
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
        element3.classList.add("oahelper_animate_in");
    } , 200);
    
    
    safari.extension.dispatchMessage("requestRecommendation", {"doi" : doi, "currentUrl" : currentUrl, "docTitle" : docTitle, "abstract" : abstract});
}

function dismissCoreRecommender(){
    doConsoleLog("Open Access Helper (Safari Extension): There were no recommendations, removing info")
    
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
        var year = "";
        var authors = "";
        var link = "";
        var foundLink = false;
        console.log(obj[i]);
        if(obj[i].yearPublished != ""){
            year = "("+obj[i].yearPublished+") ";
        }
        //get three authors & et al
        if(obj[i].authors.length > 0){
            var maxAuthors = 3;
            if(obj[i].authors.length < 3) {
                maxAuthors = obj[i].authors.length;
            }
            for(j=0; j<maxAuthors; j++){
                authors += obj[i].authors[j].name+"; ";
            }
            if (obj[i].authors.length > 3 ){
                authors += " et al.";
            }
        }
        if(obj[i].links.length > 0){
            for(k=0; k<obj[i].links.length; k++){
                if(obj[i].links[k].type == "download" && !foundLink){
                    link = obj[i].links[k].url;
                    foundLink = true;
                }
                if(obj[i].links[k].type == "display" && !foundLink){
                    link = obj[i].links[k].url;
                    foundLink = true;
                }
            }
        }
        
        var div = document.createElement('div');
        div.className = "oahelper_recommendation";
        div.innerHTML = '<p class="oahelper_recommendation_p"><a href="'+link+'" target="_blank" class="oahelper_recommendation_a">'+obj[i].title+'</a><br>'+year+authors+'</p>';
        myRecomElement.appendChild(div);
    }
    
}

function dismissCoreRecommendations(){
    var element = document.getElementById("oahelper_corerecommender_outer");
    element.parentNode.removeChild(element)
}


/**********
 *
 * Handle Specific Vendor Sites
 *
 **********/


function doIngentaConnect(oab, doistring, host){
    doConsoleLog("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
    // Ingenta Connect
    if (document.querySelectorAll("span.access-icon img[alt='Open Access']").length > 0){
        var onclick = document.querySelectorAll("a.fulltext.pdf")[0].getAttribute('onclick');
        if(onclick != null && onclick != "" && onclick.indexOf("javascript" > -1)){
            var href = onclick.replace("javascript:popup('", "").replace("','downloadWindow','900','800')", "");
            if(href != null && href != ""){
                var url = window.location.protocol+'//'+host+href;
                successfulAlternativeOAFound(url, "Free Access", true, doistring);
            }
            else{
                doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
                requestDocument(oab, doistring);
            }
        }
        else{
            var popup = document.querySelectorAll("a.fulltext.pdf")[0].dataset.popup
            if(popup != null && popup != "" && popup.indexOf("download" > -1)){
                if(popup != null && popup != ""){
                    var url = window.location.protocol+'//'+host+popup;
                    successfulAlternativeOAFound(url, "Free Access", true, doistring);
                }
                else{
                    doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
                    requestDocument(oab, doistring);
                }
            }
            else{
                doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
                requestDocument(oab, doistring);
            }
        }
        
    }
    else{
        doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found (web scraper)");
        requestDocument(oab, doistring);
    }
}

function doBmj(oab, doistring, host){
    doConsoleLog("Open Access Helper (Safari Extension): We are checking: "+host+" for hybrid journal access");
    var bmjFreeAccessClass = 'highwire-access-icon highwire-access-icon-user-access user-access bmjj-free bmjj-free-access bmjj-access-tag';
    var pdf = getMeta("citation_pdf_url")
    if(document.querySelectorAll("svg.icon-open-access").length > 0){
        if(pdf != "" && pdf.indexOf("http" == 0)){
            successfulAlternativeOAFound(pdf, "Open Access", true, doistring);
        }
        else{
            doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
            requestDocument(oab, doistring);
        }
    }
    else if(document.getElementsByClassName(bmjFreeAccessClass).length > 0){
        var freeAccess = document.getElementsByClassName(bmjFreeAccessClass);
        var bmjFree = false;
        for(i=0; i<freeAccess.length; i++){
            if(freeAccess[i].textContent == "Free" && !bmjFree){
                successfulAlternativeOAFound(pdf, "Free Access", true, doistring);
            }
        }
        if(!bmjFree){
            doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
            requestDocument(oab, doistring);
        }
    }
    else{
        doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
        requestDocument(oab, doistring);
    }
}

function doBaseSearch(oab, doistring, host){
    doConsoleLog("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
    if (document.querySelectorAll("img.pull-right[alt='Open Access']").length > 0){
        webscraperBadge("a.link-gruen.bold", false, oab);
    }
    else{
        doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
        requestDocument(oab, doistring);
    }
}

function doIEEExplore(oab, doistring, host){
    doConsoleLog("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
    if (document.querySelectorAll("i.icon-access-open-access").length > 0){
        webscraperBadge("a.doc-actions-link.stats-document-lh-action-downloadPdf_2", false, oab);
    }
    else{
        doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
        requestDocument(oab, doistring);
    }
}

function doSagePub(oab, doistring, host){
    doConsoleLog("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
    if(document.querySelectorAll("img.accessIcon.freeAccess").length > 0){
        webscraperBadge("a[data-item-name=\"download-PDF\"]", true, oab);
    }
    else{
        doConsoleLog("Open Access Helper (Safari Extension): We are checking: "+host+" for hybrid journal access");
        if(document.querySelectorAll('img.accessIcon.openAccess').length > 0){
            webscraperBadge("div.pdf-access>a", true, oab);
        }
        else{
            doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
            requestDocument(oab, doistring);
        }
    }
}

function doOup(oab, doistring, host){
    doConsoleLog("Open Access Helper (Safari Extension): We are checking: "+host+" with a web scraper");
    if(document.querySelectorAll("i.icon-availability_free").length > 0){
        webscraperBadge("a.article-pdfLink", true, oab);
    }
    else{
        doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
        requestDocument(oab, doistring);
    }
}

function doCambridge(oab, doistring, host){
    doConsoleLog("Open Access Helper (Safari Extension): We are checking: "+host+" for hybrid journal access");
    if(document.querySelectorAll("span.entitled").length > 0){
        var pdf = getMeta("citation_pdf_url")
        if(pdf != "" && pdf.indexOf("http" == 0)){
            successfulAlternativeOAFound(pdf, "Free / Subscription Access", true, doistring)
        }
    }
    else{
        doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
        requestDocument(oab, doistring);
    }
}

function doWiley(oab, doistring, host){
    doConsoleLog("Open Access Helper (Safari Extension): We are checking: "+host+" for \"Free Access\"");
    var toCheck = document.querySelectorAll("div.article-citation > div > div.doi-access-container.clearfix > div > div");
    var toCheck2 = document.getElementById("pdf-iframe");
    if(toCheck.length > 0 && toCheck[0].innerHTML.indexOf("Free Access")){
        if(toCheck2 === null){
            doConsoleLog("Open Access Helper (Safari Extension): We found FREE Access");
            var pdf = getMeta("citation_pdf_url");
            successfulAlternativeOAFound(pdf, "Free Access", true, doistring);
        }
    }
    else{
        doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
        if(toCheck2 === null){
            requestDocument(oab, doistring);
        }
        
    }
}

function doSpringerLink(oab, doistring, host){
    doConsoleLog("Open Access Helper (Safari Extension): We are checking: "+host+" for \"Free Access\"");
    var toCheck = document.querySelectorAll("div.download-article");
    if(toCheck.length > 0 && toCheck[0].innerHTML.indexOf("Download") > -1){
        doConsoleLog("Open Access Helper (Safari Extension): We found FREE / Subscription Access");
        var pdf = getMeta("citation_pdf_url");
        successfulAlternativeOAFound(pdf, "Free / Subscription Access", true, doistring);
    }
    else{
        doConsoleLog("Open Access Helper (Safari Extension): no Open Access Found");
        requestDocument(oab, doistring);
    }
}

function doTandFOnline(oab, doistring, host){
   doConsoleLog(chrome.i18n.getMessage('content_console_013', host));
   const toCheck = document.querySelectorAll('div.accessIconLocation');
   if (toCheck.length > 0 && toCheck[0].alt == 'Open access' && getMeta('citation_fulltext_world_readable').length > 0){
     doConsoleLog('Open Access Helper (Chrome Extension): We found Open Access');
     successfulAlternativeOAFound(window.location.href, 'Open Access', true, doistring);
   }
   else{
     doConsoleLog(chrome.i18n.getMessage('content_console_012'));
     requestDocument(oab, doistring);
   }
 }

function doPsycNet(){
    if(((window.location.pathname.indexOf("/search/display") > -1) || (window.location.pathname.indexOf("/record/") > - 1) || (window.location.pathname.indexOf("/fulltext/") > -1)) && oah_processedSinglePageApplication == false){
        setTimeout(function () {
            oah_processedSinglePageApplication = true;
            findDoi();
        } , 4500);
    }
}


function handlePreprintSites() {
    if (document.location.href.indexOf('www.biorxiv.org') > -1 || document.location.href.indexOf('www.medrxiv.org') > -1) {
        doBioMedArxiv();
      } else if (
        document.location.href.indexOf('osf.io/preprints') > -1 ||
        document.location.href.indexOf('engrxiv.org/') > -1 ||
        document.location.href.indexOf('biohackrxiv.org/') > -1 ||
        document.location.href.indexOf('ecsarxiv.org') > -1 ||
        document.location.href.indexOf('frenxiv.org/') > -1 ||
        document.location.href.indexOf('mediarxiv.org/') > -1
      ) {
        doOSFArxiv();
      } else if (document.location.href.indexOf('arxiv.org') > -1) {
        doArxivOrg();
      }
      else{
        //console.log('hanldePreprintSites didn\'t match');
      }
}

function doBioMedArxiv() {
  var possibleDocs = document.getElementsByClassName('article-dl-pdf-link link-icon');
  if (possibleDocs.length > 0) {
    for (var link of possibleDocs) {
      var href = link.getAttribute('href');
      if (href.indexOf('pdf') > -1) {
        // I am on Open Access
        const url = window.location.protocol+"//"+window.location.hostname+href;
        successfulAlternativeOAFound(url, 'Preprint Server', true, doistring);
      }
    }
  }
}

function doArxivOrg() {
  var possibleDocs = document.getElementsByClassName('abs-button download-pdf');
    if (possibleDocs.length > 0) {
      for (var link of possibleDocs) {
        var href = link.getAttribute('href');
        if (href.indexOf('pdf') > -1) {
          // I am on Open Access
          const url = window.location.protocol+"//"+window.location.hostname+href;
          successfulAlternativeOAFound(url, 'Preprint Server', true, doistring);
        }
      }
    }
}

function doOSFArxiv() {
  const classArray = ['btn btn-primary p-v-xs', 'btn btn-primary p-v-xsf', 'pdf-download-link'];
  classArray.forEach(className => {
    const possibleDocs = document.getElementsByClassName(className);
    if (possibleDocs.length > 0) {
      for (const link of possibleDocs) {
        const href = link.getAttribute('href');
        if (href.indexOf('download') > -1) {
          // I am on Open Access
          const url = `${href}`;
          successfulAlternativeOAFound(url, 'Preprint Server', true, doistring);
        }
      }
    }
  });
}

function doOaHelperLiveRegion(message){
    setTimeout(function () {
        var div = document.getElementById("oahelper_LiveRegion");
        if(div != null){
            div.innerHTML = message;
        }
    } , 4000);
}

function addCitationCount(count, doi){
    doConsoleLog("Open Access Helper (Safari Extension): This article was cited "+count+" times, according to OpenCitations.net");
    
    var url = "https://www.oahelper.org/opencitations/?doi="+doi;
    var message = "Times Cited: "+count;
    var src = safari.extension.baseURI + "ocicon.svg";
    var div = document.createElement('div');
    
    div.innerHTML = '<div class="oahelper_opencitations" onclick="window.open(\''+url+'\')" title="OpenCitations '+message+'"><img id="oahelper_opencitations_logo" src="'+src+'" align="left" title="'+message+'" data-oaurl="'+url+'" data-badge="" data-citcount="'+count+'"/><span id="oahelper_opencitations_msg">'+message+'</span></div><span id="oahelper_opencitations_LiveRegion" role="alert" aria-live="assertive" aria-atomic="true"></span>'; // data-oaurl is a gift to ourselves
    div.id = 'oahelper_opencitations_outer';
    div.className = 'oahelper_opencitations_outer';
    
    if(document.body.parentNode.parentNode != "#document"){
        document.body.appendChild(div);
    }
    
}

function doConsoleLog(message) {
  if (configuration['consolelog'] != undefined && !configuration['consolelog']) {
    console.log(message);
  }
}

function getPopupAnswer() {
  let response = {
    oaurl: '',
    oastatus: '',
    citationcount: 0,
    citationurl: '',
    currenturl: window.location.href,
    isIll: '',
    doi: ''
  };

  const oaurlElement = document.getElementById('oahelper_doicheckmark');
  const oaStatusElement = document.getElementById('oahelper_oahelpmsg');
  const citationElement = document.getElementById('oahelper_opencitations_msg');
  const citationUrlElement = document.getElementById('oahelper_opencitations_logo');
  
  if(oaurlElement != undefined){
    if (oaurlElement.dataset.badge != undefined) {
        response.isIll = oaurlElement.dataset.badge;
    }
      
    if (oaurlElement.dataset.doi != undefined) {
        response.doi = oaurlElement.dataset.doi;
    }
      
    if (oaurlElement.dataset.oaurl) {
        response.oaurl = oaurlElement.dataset.oaurl;
    }
  }

  if (oaStatusElement != undefined) {
    response.oastatus = oaStatusElement.innerText;
  }

  if (citationUrlElement != undefined) {
      response.citationcount = parseInt(citationUrlElement.dataset.citcount);
  }

  if (citationUrlElement != undefined) {
      response.citationurl = citationUrlElement.dataset.oaurl;
  }
  return response;
}

function hideBadgeRequest() {
  if (document.getElementById('oahelper_doifound_outer') != null) {
    document.getElementById('oahelper_doifound_outer').style.display = 'none';
  }
  if (document.getElementById('oahelper_opencitations_outer') != null) {
    document.getElementById('oahelper_opencitations_outer').style.display = 'none';
  }
  if (document.getElementById('oahelper_corerecom_outer') != null) {
    document.getElementById('oahelper_corerecom_outer').style.display = 'none';
  }
}
