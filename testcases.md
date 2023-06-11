# Test Cases

The purpose of this document is to provide insight into the test cases I utilize during release testing of Open Access Helper (for Safari). Sadly, there is always a chance that a test case, which was true today, will be false tomorrow. If you come across a problem with Open Access Helper, feel free to eMail me at oahelper@otzberg.net and provide as much description as possible.

Due to time constraints during testing, I am not interested to grow this list indefinately, however if there is a publisher you know and trust and are able to contribute test cases, use the eMail address above to provide me with cases. I love to have cases for the three main cases I am testing for.

# Explanation

* No Badge
    * No Open Access found
* Orange
    * Open Access found at different location
    * Potentially I was just not able to follow through to finaly location
* Green 
    * Open Access at this location


# Sites

There is no specific order to these sites, many of them were added in the order I added them during development and while there are thousands of publishers out there, I only test across the few below. Thus, if you have a really important case, send it my way.

Please note that I will try to limit "screen scraping" cases to the bare minimum, as these tend to break frequently and will be hard to maintain.

## Nature

* No Badge [OAB | OC | CORE_Recom]: http://www.nature.com/articles/ngeo2372     
* Orange [OC]: https://www.nature.com/articles/nature21360   
* Orange [OC]: http://www.nature.com/articles/nature17448    

## ScienceDirect

* No Badge [OAB | CORE_Recom]: https://www.sciencedirect.com/science/article/pii/B9780128012383651036  
* No Badge [OC]: https://www.sciencedirect.com/science/article/pii/S0742051X16306692   
* Orange [OC]: https://www.sciencedirect.com/science/article/pii/S2352345X18301188  
* Green [OC]: https://www.cmghjournal.org/article/S2352-345X(18)30118-8/fulltext      
* Orange [OC]: https://www.sciencedirect.com/science/article/pii/S0040580910000791       

## PubMed

* Orange [-]: https://www.ncbi.nlm.nih.gov/pubmed/30468734                          
* Orange [OC]: https://www.ncbi.nlm.nih.gov/pubmed/30258935             
* Green [OC]: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6147107/     

## BMJ

* Green [OC]: https://ard.bmj.com/content/78/3/421 (Hybridge)            

## IEEE:

* No Badge [OC | CORE_Recom]: https://ieeexplore.ieee.org/document/6197616                
* Orange [OC]: http://ieeexplore.ieee.org/document/6512846/                  
* Green [OC]: https://ieeexplore.ieee.org/document/8440671 (oadoi)           
* Green [OC]: https://ieeexplore.ieee.org/document/8454727 (web scraping)    

## Sage Publishing

* No Badge [CORE_Recom]: https://journals.sagepub.com/doi/pdf/10.1177/001979396001400128
* No Badge [OAB | OC | CORE_Recom]: https://journals.sagepub.com/doi/full/10.1177/0956797616674999           
* Orange [OC]: https://journals.sagepub.com/doi/full/10.1177/1474515116687178                
* Green [-]: https://journals.sagepub.com/doi/full/10.1177/1536504211418465 (Open Access)               
* Green [OC]: https://journals.sagepub.com/doi/abs/10.1177/1947603519828432 (unpaywall.org)   

## Wiley

* No Badge [OAB | OC | CORE_Recom]: https://iubmb.onlinelibrary.wiley.com/doi/10.1002/iub.2222                  
* Green [OC]: https://stemcellsjournals.onlinelibrary.wiley.com/doi/10.1002/stem.2571        
* Orange [OC]: https://onlinelibrary.wiley.com/iucr/doi/10.1107/S1600577517008372           
* Green [OC]: https://onlinelibrary.wiley.com/doi/10.1002/ijc.28702                         

## IngentaConnect

* No Badge [OAB | CORE_Recom]: https://www.ingentaconnect.com/content/bpl/ijc/2020/00000147/00000012/art00025  
* Orange [OC]: https://www.ingentaconnect.com/content/wk/hyp/2018/00000071/00000001/art00017     
* Orange [OC]: https://www.ingentaconnect.com/content/sp/mmr/2016/00000013/00000003/art00117     
* Orange [OC]: https://www.ingentaconnect.com/content/sp/ijo/2010/00000037/00000002/art00013     
* Green [OC]: https://www.ingentaconnect.com/contentone/cog/or/2017/00000025/00000004/art00007   

## Springer Link

* No Badge [OC | CORE_Recom]: https://link.springer.com/article/10.1007/s11684-014-0315-5         
* Orange [OC]: https://link.springer.com/article/10.1186/1479-5876-8-42              
* Green[OC]: https://link.springer.com/article/10.1007/s10108-003-0072-0

## Oxford University Press

* No Badge [OC | CORE_Recom]: https://academic.oup.com/jid/article-abstract/136/6/754/830381?redirectedFrom=fulltext              
* Green [OC]: https://academic.oup.com/ibdjournal/article-abstract/16/9/1514/4628438?redirectedFrom=fulltext
* Green [OC]: https://academic.oup.com/jac/article/73/4/833/4840684 

## Cambridge University Press:

* No Badge [OC | CORE_Recom]: https://www.cambridge.org/core/journals/the-british-journal-of-psychiatry/article/cancer-and-depression/3B0E0259637B48B503908D2F7252A9F9    
* Orange [OC]: https://www.cambridge.org/core/journals/journal-of-laryngology-and-otology/article/topical-chemoprevention-of-skin-cancer-in-mice-using-combined-inhibitors-of-5lipoxygenase-and-cyclooxygenase2/B570AB399B995BD21221D405DADAD62B     
* Green [OC]: https://www.cambridge.org/core/journals/british-journal-of-nutrition/article/resistant-carbohydrates-stimulate-cell-proliferation-and-crypt-fission-in-wildtype-mice-and-in-the-apcmin-mouse-model-of-intestinal-cancer-association-with-enhanced-polyp-development/DBEB6AC22DEFADC33C73411520F8FCFA    

## GetTheResearch

* https://gettheresearch.org -> search for -- vaccines and autism -- click on learn more next to an article

## PsycNet.apa.org

* Note: There is a 4.5 second delay on detecting DOIs for this SPA*

* https://psycnet.apa.org -> search for -- adhd -- click an article
* https://psycnet.apa.org/record/2019-80678-001 (recommendations & OAB)
* https://psycnet.apa.org/doi/10.1037/neu0000590

## ProQuest 
* Orange [OC]: https://www.proquest.com/docview/2246651524/BAB1D866B3CE4895PQ/7

## EBSCO example
* Orange: Login through http://www.libraryresearch.com/ adnd search for AN 144426220    
