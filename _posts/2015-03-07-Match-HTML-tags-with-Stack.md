---
title: Match HTML tags with Stack ADT
author: Junyang
layout: post
permalink: /Match-HTML-Tags/
categories: 
tags:
  - [java, DS]
---
{% include JB/setup %}

**The following example shows how to use stack ADT to check if HTML tags are matched in a .html file.**

Generally, it contains three steps:
> 1. Define Stack interface
2. Implement Stack interface based on linked list 
3. Use Stack_List to implement HTML tags match algorithm

<!--more-->
##Stack Interface Definition 
A Stack ADT provides five operations, named:  
- push(Object ele): push the element as the top element in Stack, return null.
- pop(): if Stack is not empty, remove and return the top element, return type is Object.
- getSize(): return the number of elements in Stack, return type is int. 
- isEmpty(): check whether Stack is empty, return type is boolean.
- top(): if Stack is not empty, return the top element(not remove), return type is Object.

```java
//Normally, a package name needs to be added. For simplicity, package information is omitted. 
public class ExceptionStackEmpty extends RuntimeException {
	public ExceptionStackEmpty(String err) {
		super(err);
	}
}
```
```java
public interface Stack {
	public void push(Object ele);
	public Object pop() throws ExceptionStackEmpty;
	public int getSize();
	public boolean isEmpty();
	public Object top() throws ExceptionStackEmpty;
}
```
##Stack_List Implementation
###Single Linked_List Node 
The stack is based on single linked_list. First of all, we need to implement a single linked_list node.
<img src="/images/linkedlist.png" style="display:block;margin:auto"/>  
<center>Single Linked_List Structure</center> 

```java
public class Node {
	private Object element; //data reference
	private Node next; //next Node reference

	public Node() {
		this(null, null)
	}

	public Node(Object ele, Node n) {
		element = e;
		next = n;
	}

	//getter & setter for data, setter with return value 
	public Object getElem() {
		return element;
	}

	public Object setElem(Object e) {
		Object oldEle = element; element = e; return oldEle;
	}

	//getter & setter for next Node
	public NOde getNext() {
		return next;
	}

	public void setNext(Node nextNode) {
		next = nextNode;
	}
}
```
###Implement Stack by single linked list
Let the first element of the single linked list to be the top of Stack to ensure push and pop operation finished in O(1). Additionally, in order to ensure getSize() method also finished in O(1), a variable is needed to record the number of elements in Stack.

```java
public class Stack_List implements Stack {
	private Node top; //reference of the top of Stack
	private int size; //number of elements in Stack

	public Stack_List() {
		top = null;
		size = 0;
	}

	//override methods of Stack interface
	public int getSize() {
		return size;
	}

	public boolean isEmpty() {
		return (top == null) ? true : false;
	}
	
	public void push(Object ele) {
		Node v = new Node(ele, top); //create a new Node, let it be the top of Stack 
		top = v; //update top
		size++; //update Stack size
	}

	public Object top() throws ExceptionStackEmpty {
		if(isEmpty())
			throw new ExceptionStackEmpty("Stack is Empty");
		return top.getElem();
	}

	public Object pop() throws ExceptionStackEmpty {
		if(isEmpty())
			throw new ExceptionStackEmpty("Stack is Empty");
		Object temp = top.getElem(); 
		top = top.getNext(); //update top 
		size--; //update Stack size
		return temp;
	}
}
```	
As presented above, if n elements stored in Stack, besides countable variable instance needed, only n Nodes needs. In other words, the space complexity is O(n), simply depends on the size of Stack.
	
##Tags Match Algorithm Implementation
In a HTML file, tags are appeared in pairs. Therefore, tags can be divided into opening tags such as &lt;body>, &lt;h1>, &lt;p> and closing tags such as &lt;/body>, &lt;/h1>, &lt;/p>. Following is an example to implement tag matching algorithm.  
In short, tags appeared in a HTML file are stored in a tag array. Then, Stack ADT is used to check if opening tags and closing tags are matched in the tag array.

```java
import java.util.stringTokenizer;
import Stack;
import Stack_List;
import java.io.*;

public class HTML {
	public static class Tag {
		String name;
		boolean opening; //check if current tag is an opening tag
	    public Tag() {
			name = "";
			opening = false;
		}
		public Tag(String nm, boolean type) {
			name = nm;
			opening = type;
		}
		//getters
		public boolean isOpening() {
			return opening;
		}
		public String getName() {
			return name;
		}
	}

	private void indent(int level) {
		for(int k=0; k<level; k++)
			System.out.print("\t |");
	}

	//check if opening tags and closing tags are matched, input is a tag array 
	public boolean isHTMLMatched(Tag[] tag) {
		int level = 0; //level of the tag
		Stack S = new Stack_List();
		for(int i=0; (i<tag.length) && (tag[i] != null); i++) { //check tag one by one
			if(tag[i].isOpening()) {
				S.push(tag[i].getName()); //push opening tag in Stack
				indent(level++);
				System.out.println("\t [" + tag.getName());
			} else { //current tag is a closing tag
				if(S.isEmpty())
					return false;
				if(!((String)S.pop()).equals(tag[i].getName()))
					return false;
				indent(--level);
				System.out.println("\t ]" + tag.getName());
			}
		}
		//The entire array(the file) is checked
		if(S.isEmpty())
			return true;
		else
			return false;
	}

	public static final int CAPACITY = 1000; //The maximam number of tags stored

	public Tag[] parseHTML(BufferedReader r) throws IOException {
		String line; //Current read line in the file
		boolean inTag = false; //whether the current checked token is a Tag
		Tag[] tag = new Tag[CAPACITY]; //The array that stored tags
		int index = 0; //The index of current tag in array
		while((line = r.readLine()) != null) {
			StringTokenizer st = new StringTokenizer(line, "<> \t", true)
			//<> is the feature of tag and it also iterated as token
			while(st.hasMoreTokens()) { //Iterate tokens(move cursor)
				String token = (String) st.nextToken();
				if(token.equals("<")) //The next tag is coming
					inTag = true;
				else if(token.equals(">")) //The current tag is finished
					inTag = false;
				else if(inTag) {
					if((token.length() == 0) || (token.charAt(0) != '/')) //The feature of an opening tag
						tag[index++] = new Tag(token, true);
					else
						tag[index++] = new Tag(token.substring(1), false);
						//if current token is a closing tag, delete '/' and stored it in array 
				}
			}
		}
		return tag;
	}

	public static void main(String[] args) {
		BufferedReader br = new BufferedReader(new InputStreamReader(HTML.class.getResourceAsStream("test.html")));
		//put test.html in the src directory. It will be with other class bytecode object after compile
		//Utilize JAVA reflection mechanism to let ClassLoaderload the file as InputStream
		HTML tagChecker = new HTML();
		if(tagChecker.isHTMLMatched(tagChecker.parseHTML(br)))
			System.out.println("The file meet HTML tag requirement");
		else
			System.out.println("The file fails to meet HTML tag requirement");
			
	}
}
```
