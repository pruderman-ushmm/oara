


// 
// This file shows the minimum you need to provide to BookReader to display a book
//
// Copyright(c)2008-2009 Internet Archive. Software license AGPL version 3.

// Create the BookReader object
br = new BookReader();
//br.displayedIndices = [1, 3];

br.canRotatePage = function(index) { alert(index); return true; }

// Return the width of a given page.  Here we assume all images are 800 pixels wide
br.getPageWidth = function(index) {
    console.debug('getPageWidth ' + index);
    if (ushmm_book_data[index]) {
        console.log(ushmm_book_data[index].width);
        return parseInt(ushmm_book_data[index].width);
    } else {
        console.log(null);
        return null;
    }

//    return 800;
}

// Return the height of a given page.  Here we assume all images are 1200 pixels high
br.getPageHeight = function(index) {
    console.debug('getPageHeight ' + index);

    if (ushmm_book_data[index]) {
        console.log(ushmm_book_data[index].height);
        return parseInt(ushmm_book_data[index].height);
    } else {
        console.log(null);
        return null;
    }
//    return 1200;
}

// We load the images from archive.org -- you can modify this function to retrieve images
// using a different URL structure
br.getPageURI = function(index, reduce, rotate) {
//    console.debug('getPageURI ' + index);


    // reduce and rotate are ignored in this simple implementation, but we
    // could e.g. look at reduce and load images from a different directory
    // or pass the information to an image server

   // var leafStr = '000';            
   // var imgStr = (index+1).toString();
   // var re = new RegExp("0{"+imgStr.length+"}$");
   // var url = 'http://www.archive.org/download/BookReader/img/page'+leafStr.replace(re, imgStr) + '.jpg';

   // return url;
 
    if (ushmm_book_data[index]) {
        return ushmm_book_data[index].fq_image_asset_url;
    } else {
        return null;
    }


}

// Return which side, left or right, that a given page should be displayed on
br.getPageSide = function(index) {
    console.log('getPageSide ' + index);


if (index==-1) {
    console.log('L');
    return 'L';
}


    if (ushmm_book_data[index]) {
        console.log(ushmm_book_data[index].page_side);
        return ushmm_book_data[index].page_side;
    } else {
        console.log(null);
        return null;
    }

    // if (0 == (index & 0x1)) {
    //     return 'R';
    // } else {
    //     return 'L';
    // }
}

// This function returns the left and right indices for the user-visible
// spread that contains the given index.  The return values may be
// null if there is no facing page or the index is invalid.
br.getSpreadIndices = function(pindex) {   
    var spreadIndices = [null, null]; 
    if ('rl' == this.pageProgression) {
        alert('RTL!');
        // Right to Left
        if (this.getPageSide(pindex) == 'R') {
            spreadIndices[1] = pindex;
            spreadIndices[0] = pindex + 1;
        } else {
            // Given index was LHS
            spreadIndices[0] = pindex;
            spreadIndices[1] = pindex - 1;
        }
    } else {


        // Left to right
        if (this.getPageSide(pindex) == 'L') {
            spreadIndices[0] = pindex;
            spreadIndices[1] = pindex + 1;
        } else {
            // Given index was RHS
            spreadIndices[1] = pindex;
            spreadIndices[0] = pindex - 1;
        }


if (pindex==-1) {
    spreadIndices[0] = -1;
    spreadIndices[1] = 0;
}


    }
    
    console.log('getSpreadIndices: ' + pindex + ' ' + spreadIndices[0] + ' ' + spreadIndices[1]);
    return spreadIndices;
}

// For a given "accessible page index" return the page number in the book.
//
// For example, index 5 might correspond to "Page 1" if there is front matter such
// as a title page and table of contents.
br.getPageNum = function(index) {
    console.log('getPageNum ' + index);

//    return index+1;
    if (ushmm_book_data[index]) {
        console.log(ushmm_book_data[index].page_designation);
        return ushmm_book_data[index].page_designation;
    } else {
        console.log(null);
        return null;
    }
}

// Total number of leafs
//br.numLeafs = function () { return 15 };
br.numLeafs = 683;

// Book title and the URL used for the book title link
br.bookTitle= 'Open Library BookReader Presentation';
br.bookUrl  = 'http://openlibrary.org';

// Override the path used to find UI images
br.imagesBaseURL = 'css/images/';

br.getEmbedCode = function(frameWidth, frameHeight, viewParams) {
    return "Embed code not supported in bookreader demo.";
}



br.ushmmBookGo = function (path_info_data) {
    // $.get("book_json", function(data) {
    //   ushmm_book_data = JSON.parse(data);
    //   console.log("Data Loaded: " + data);
    //   console.debug(ushmm_book_data);
    // });


    successFunction = function(data) {
      ushmm_book_data = JSON.parse(data);
      console.log("Data Loaded: " + data);
      console.debug(ushmm_book_data);
    }

    $.ajax({
      url: '/br/book_json'+path_info_data,
//      data: data,
      success: successFunction,
//      dataType: dataType
      async: false
    });


    // Let's go!
    br.init();


    br.updateTOC([
       {
           "pagenum": "2",
           "level": 1,
           "label": "CHAPTER I",
           "type": {"key": "/type/toc_item"},
           "title": "THE COUNTRY AND THE MISSION"
       }
    ]);



    // read-aloud and search need backend compenents and are not supported in the demo
//     $('#BRtoolbar').find('.read').hide();
//     $('#textSrch').hide();
//     $('#btnSrch').hide();
}

xx = '/root/USHMM/RG-15.118M/1'
xxx = '/root/USHMM/RG-69.005M/1'
//br.ushmmBookGo(xxx)
