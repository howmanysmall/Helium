"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[539],{3905:function(e,t,n){n.d(t,{Zo:function(){return u},kt:function(){return f}});var r=n(67294);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function o(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,r,a=function(e,t){if(null==e)return{};var n,r,a={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var s=r.createContext({}),c=function(e){var t=r.useContext(s),n=t;return e&&(n="function"==typeof e?e(t):o(o({},t),e)),n},u=function(e){var t=c(e.components);return r.createElement(s.Provider,{value:t},e.children)},d={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},p=r.forwardRef((function(e,t){var n=e.components,a=e.mdxType,i=e.originalType,s=e.parentName,u=l(e,["components","mdxType","originalType","parentName"]),p=c(n),f=a,m=p["".concat(s,".").concat(f)]||p[f]||d[f]||i;return n?r.createElement(m,o(o({ref:t},u),{},{components:n})):r.createElement(m,o({ref:t},u))}));function f(e,t){var n=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var i=n.length,o=new Array(i);o[0]=p;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l.mdxType="string"==typeof e?e:a,o[1]=l;for(var c=2;c<i;c++)o[c]=n[c];return r.createElement.apply(null,o)}return r.createElement.apply(null,n)}p.displayName="MDXCreateElement"},73868:function(e,t,n){n.r(t),n.d(t,{frontMatter:function(){return l},contentTitle:function(){return s},metadata:function(){return c},toc:function(){return u},default:function(){return p}});var r=n(87462),a=n(63366),i=(n(67294),n(3905)),o=["components"],l={sidebar_position:4},s="Why I modified Rocrastinate",c={unversionedId:"WhyIModifiedRocrastinate",id:"WhyIModifiedRocrastinate",isDocsHomePage:!1,title:"Why I modified Rocrastinate",description:"Helium is after all a fork of Rocrastinate. I've always loved the library and I wished it was updated still, so I took the updating into my own hands.",source:"@site/docs/WhyIModifiedRocrastinate.md",sourceDirName:".",slug:"/WhyIModifiedRocrastinate",permalink:"/Helium/docs/WhyIModifiedRocrastinate",editUrl:"https://github.com/howmanysmall/Helium/edit/main/docs/WhyIModifiedRocrastinate.md",tags:[],version:"current",sidebarPosition:4,frontMatter:{sidebar_position:4},sidebar:"defaultSidebar",previous:{title:"Why use Helium?",permalink:"/Helium/docs/WhyUseHelium"}},u=[],d={toc:u};function p(e){var t=e.components,n=(0,a.Z)(e,o);return(0,i.kt)("wrapper",(0,r.Z)({},d,n,{components:t,mdxType:"MDXLayout"}),(0,i.kt)("h1",{id:"why-i-modified-rocrastinate"},"Why I modified Rocrastinate"),(0,i.kt)("p",null,"Helium is after all a fork of Rocrastinate. I've always loved the library and I wished it was updated still, so I took the updating into my own hands."),(0,i.kt)("p",null,"I've added quite a few things to the library over the base version of Rocrastinate, being:"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"Janitor over Maid."),(0,i.kt)("li",{parentName:"ul"},"RedrawBinding is an Enum to add autofill support."),(0,i.kt)("li",{parentName:"ul"},"PascalCase for the entire API."),(0,i.kt)("li",{parentName:"ul"},"Lifecycle events for Components."),(0,i.kt)("li",{parentName:"ul"},"Store is now a metatable class instead of a function that returns a table."),(0,i.kt)("li",{parentName:"ul"},"Components can now be redrawn on ",(0,i.kt)("inlineCode",{parentName:"li"},"Stepped")," in addition to ",(0,i.kt)("inlineCode",{parentName:"li"},"Heartbeat"),", ",(0,i.kt)("inlineCode",{parentName:"li"},"RenderStep"),", and ",(0,i.kt)("inlineCode",{parentName:"li"},"RenderStepTwice"),"."),(0,i.kt)("li",{parentName:"ul"},"Various small optimizations that can be configured using the GlobalConfiguration object."),(0,i.kt)("li",{parentName:"ul"},"The ",(0,i.kt)("inlineCode",{parentName:"li"},"Make")," function for easy Instance creation."),(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("inlineCode",{parentName:"li"},"MakeActionCreator")," makes it less annoying to create action creators."),(0,i.kt)("li",{parentName:"ul"},"A port of ",(0,i.kt)("a",{parentName:"li",href:"https://github.com/Reselim/Flipper"},"Flipper")," for Helium Components, called ",(0,i.kt)("a",{parentName:"li",href:"https://github.com/howmanysmall/Hydrogen"},"Hydrogen"),", which is used for animation.")),(0,i.kt)("p",null,"The library itself may be old but it's extremely fast, and has basically all you could need for a UI library."))}p.isMDXComponent=!0}}]);