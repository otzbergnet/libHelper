document.addEventListener("DOMContentLoaded", function(event) {
    //do nothing right now
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
        oafound(event.message)
    }
}

function findDoi(){
    var doi = getMeta('citation_doi');
    if(doi != ""){
        safari.extension.dispatchMessage("found", {"doi" : doi});
    }
    else{
        findDoi1()
    }
    
}

function findDoi1(){
    var doi = getMetaScheme('dc.Identifier', 'doi');
    if(doi != ""){
        safari.extension.dispatchMessage("found", {"doi" : doi});
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


function currentUrl() {
    return safari.application.activeBrowserWindow.activeTab.url;
}

function oafound(message){
    var div = document.createElement('div');
    div.innerHTML = '<div id="cntdwn">10</div><div><a href="'+message.url+'">We found an OpenAccess Version of this document. Click to access!</a></div>';
    div.className = 'doifound'
    div.setAttribute('id', 'doifound');
    
    if(document.body.parentNode.parentNode != "#document"){
        document.body.insertBefore(div, document.body.firstChild);
    }
    countDown()
    setTimeout(
        function(){
            div.parentNode.removeChild(div);
        },
    10000);
}

function countDown(){
    var i = 0;
    var id = document.getElementById("cntdwn");
    var trackCall = setInterval(function () {
        if (i == 9) {
            clearInterval(trackCall);
        }
        else{
            id.innerHTML = 9-i;
            i++;
        }
    }, 1000);
}

function inIframe () {
    try {
        return window.self !== window.top;
    } catch (e) {
        return true;
    }
}
