+++
date = "2015-09-17T18:36:06+03:00"
title = "Full-text search and indexing with Bleve - Part 1"
description = "My first steps using Bleve Search"
tags = [ "golang", "bleve", "full-text search", "indexing" ]

+++

### The problem
The well know ElasticSearch and Apache Solr, written in Java, are complete solutions, but I don't want to execute the JVM (a.k.a. memory lover) on my server. Yes, I'm cheap.

### The lover
[Go](http://golang.org/). It's an easy to learn, simple, robust and performative programming language. I have been using Go for almost everything (I still have some Ruby on Rails/PHP/Python running around).

[Google it _golang_](http://lmgtfy.com/?q=golang) and meet the happiness.

## The solution
[Bleve](http://www.blevesearch.com/): It's a **text indexing** package for Go. Yes, a package! You **don't need an extra service + connector/library** to have text indexing with scoring, faceting and highlights in your service.

The package is a mix of pure Go features and wrappers to some C/C++. In the article **We'll only use the pure Go features**. If you need a little bit more power: go to the [Bleve build docs](http://www.blevesearch.com/docs/Building/) and learn how to do it.

<!--more-->

To exemplify the use, I'll create an "Event Finder". I don't know your database preferences (I've been living inside MongoDB/Redis databases on the last 2 years), but I know something who everyone can run... SQLite3!

The objective is to create some events, create an index for them and retrieve some data using the Bleve Search.

### Let's code!
What? Don't you have Go on your machine? Shame on you! [https://golang.org/doc/install](https://golang.org/doc/install)

First, setup our project workspace.

```bash
# My Go studies project/folder
mkdir -p ~/Workspace/Go
cd ~/Workspace/Go
# Exporting the env var GOPATH to the actual directory
export GOPATH=`pwd`
# Creating and accessing the project folder
mkdir -p ~/Workspace/Go/src/github.com/nassor/studies-blevesearch
cd ~/Workspace/Go/src/github.com/nassor/studies-blevesearch
```

Now let's download the package to our $GOPATH environment. The purpose isn't database implementation, so to not loose too much time working with the SQL database, we will use the ORM package called [gorm](https://github.com/jinzhu/gorm).

```bash
go get github.com/blevesearch/bleve/... # bleve package
go get github.com/mattn/go-sqlite3      # sqlite3 package
go get github.com/jinzhu/gorm           # orm package
```

Everything is ready, so let's learn how to create an index connection. We'll create a **BleveConn** method to create or connect to the indexing persistence. The Bleve Search uses the [BlotDB](https://github.com/boltdb/bolt) as the default persistence, but you can choose [others](https://github.com/blevesearch/blevex).

~~~go
package conn

import "github.com/blevesearch/bleve"

var bleveIdx bleve.Index

// Bleve connect or create the index persistence
func Bleve(indexPath string) (bleve.Index, error) {

	// with bleveIdx isn't set...
	if bleveIdx == nil {
		var err error
		// try to open de persistence file...
		bleveIdx, err = bleve.Open(indexPath)
		// if doesn't exists or something goes wrong...
		if err != nil {
			// create a new mapping file and create a new index
			mapping := bleve.NewIndexMapping()
			bleveIdx, err = bleve.New(indexPath, mapping)
			if err != nil {
				return nil, err
			}
		}
	}

	// return de index
	return bleveIdx, nil
}
~~~
<small>Ref: *github.com/nassor/studies-blevesearch/conn/bleve.go*</small>
<small>Ref: [*github.com/nassor/studies-blevesearch/conn/bleve.go*](https://github.com/nassor/studies-blevesearch/blob/master/conn/bleve.go)</small>

Let's start with our model. It is a classic Event data:

~~~go
// Event is an event! wow! ;D
type Event struct {
	ID          int
	Name        string
	Description string
	Local       string
	Website     string
	Start       time.Time
	End         time.Time
}

// Index is used to add the event in the bleve index.
func (e *Event) Index(index bleve.Index) error {
	err := index.Index(string(e.ID), e)
	return err
}
~~~
<small>Ref: [*github.com/nassor/studies-blevesearch/models/event.go*](https://github.com/nassor/studies-blevesearch/blob/master/models/event.go)</small>

I add a method called Index, it receives as parameter a *bleve.Index struct* and return an error. The method is in charge to **add the event in the index**.

The *bleve.Index.Index()* method accept only string to identify. Because we are using the [Default IndexMapping](http://www.blevesearch.com/docs/Index-Mapping/), all the fields in the type Event will be indexed.

Below, the code I use to test the functionality:

~~~go
func TestIndexing(t *testing.T) {
	_, eventList := dbCreate()
	idx := idxCreate()

	err := eventList[0].Index(idx)
	if err != nil {
		t.Error("Wasn't possible create the index", err, ballotX)
	} else {
		t.Log("Should create an event index", checkMark)
	}

	idxDestroy()
	dbDestroy()
}
~~~
<small>Ref: [*github.com/nassor/studies-blevesearch/models/event_test.go*](https://github.com/nassor/studies-blevesearch/blob/master/models/event_test.go)</small>

Simple, isn't? To retrieve the data we need a little bit more steps, but not too much. :)

~~~go
func TestFindByAnything(t *testing.T) {
	db, eventList := dbCreate()
	idx := idxCreate()
	indexEvents(idx, eventList)

	// We are looking to an Event with some string which match with dotGo
	query := bleve.NewMatchQuery("dotGo")
	searchRequest := bleve.NewSearchRequest(query)
	searchResult, err := idx.Search(searchRequest)
	if err != nil {
		t.Error("Something wrong happen with the search", err, ballotX)
	} else {
		t.Log("Should search the query", checkMark)
	}

	if searchResult.Total != 1 {
		t.Error("Only 1 result are expected, got ", searchResult.Total, ballotX)
	} else {
		t.Log("Should return only one result", checkMark)
	}

	event := &Event{}
	db.First(&event, &searchResult.Hits[0].ID)
	if event.Name != "dotGo 2015" {
		t.Error("Expected \"dotGo 2015\", Receive: ", event.Name)
	} else {
		t.Log("Should return an event with the name equal a", event.Name, checkMark)
	}

	idxDestroy()
	dbDestroy()
}
~~~
<small>Ref: [*github.com/nassor/studies-blevesearch/models/event_test.go*](https://github.com/nassor/studies-blevesearch/blob/master/models/event_test.go)</small>

You have access to the code [here](https://github.com/nassor/studies-blevesearch). Pull the code, change it and have fun. **\o/**

And that's it! I'm here studying how to make more complex searches. When I have something new, I'll write the second part.

----------

**P.S.:** Writing this article I had the idea to use the BlotDB as the main persistence, a simple key/value instead a SQL/NoSQL/NewSQL database. The point came with this thought: "why I need a second query structure if I'll use Bleve to do queries?". I'll write an article about my studies about that too.
