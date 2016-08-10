---
title: Thinking Recursively
author: Junyang
layout: post
permalink: /Thinking-Recursively/
tags: 
  - OCaml
---
{% include JB/setup %}

In this article, I will share my thoughts on recursively thinking in OCaml. Lists and natural numbers are used to illustrate recursively thinking. **Insertion Sort Algorithm** will also be presented.

<!--more-->

When analyzing data structures such as tuples, pairs and options -- only a small, finite amount of work are needed to extract all the information contained. While in DS such as lists, trees and graphs which are recursively defined DS -- we do need recursive functions to get all the information contained.

##Natural Numbers
Natural numbers can be defined inductively, i.e. taken as recursive data.
A natural number **n** is either
- 0, or
- m + 1 where m is a smaller natural number 

An Example: Double the input if it is non-negative, fails if the input is negative.

	let double (n:int) : int =  (* nest double_nat so it can only be called by double *)
		let rec double_nat (n:int) : int =
			match n with
			| 0 -> 0
			| n -> 2 + double_nat (n-1) 
		in

        if n < 0 then
			failwith "negative input!"  (* raise exception *)
		else
			double_nat n
	;;

Actually, natural numbers can be taken as different recursively data based on different theorems. 
> At present stage, there is **no built-in type for natural numbers, only integers**, therefore funtions are **started with assertions** to ensure it only called with natural numbers. However, we can define our own abstract type of natural numbers later.

Thereom: For all natural numbers n, if n is not 0 and not 1 then n-2 is a (smaller) natural number.

	let rec f (n:int) : int =
		assert (0 <= n);
		match n with
		| 0 -> ... no recursive calls to f ...
		| 1 -> ... no recursive calls to f ...
		| _ -> ... f (n-2) ... f (n-2) ...
	;;

Another thereom: For all natural numbers n, if n is not 0 then n/2 is a (smaller) natural number.

	let rec f (n:int) : int =
		assert(0 <= n);
		match n with
		  0 -> ... no recursive calls to f ...
		| _ -> ... f (n/2) ...
	;;

##Lists 
Every list has one of two forms:
- [] -- an empty list
- hd::tail -- a non-empty list with first element hd followed by some other (smaller) list tail.

> In OCaml, **the type list does not contain any infinitely long lists** (i.e. exclude cyclic structure). Recursive functions that only called recursively on smaller lists (hd::tail -> ... f tail), thus letting it terminates. 

An Example: Given a list of pairs. produce a list of the products of those pairs.

	let rec prods (xs : (int * int) list) : int list =
		match xs with
		  [] -> []
		| (x,y) :: tail -> (x*y) :: prods tail
	;;

	assert(prods [] = []);;
	assert(prods [(2,4); (3,7)] = [8; 21]);;

Another Example: A function that takes two lists as arguments and returns an optional list of pairs. Return None if the lists have different lengths. Return Some if the lists have the same length.

	let rec zip (xs : int list) (ys : int list) : (int * int) list option =
		match (xs,ys) with
		| ([], []) -> Some []
	    | (x::xtail, y::ytail) ->
			(match zip xtail ytail with
			  None -> None
			| Some zs -> Some ((x,y) :: zs))
		| (_, _) -> None
	;;

	assert (zip [] [] = Some []);;
	assert (zip [2] [] = None);;
	assert (zip [] [2] = None);;
	assert (zip [2;3] [4;5]) = Some [(2,4);(3,5)];; 

>It is always a good idea to surround inner match statements with parentheses to avoid confusion.

###Insertion Sort
Algorithm

<img src="/images/is1.png" style="display:block;margin:auto"/>
<center>take the next item in the unsorted list</center>

<img src="/images/is2.png" style="display:block;margin:auto"/>
<center>insert it into the sorted position in the sorted list</center>

Factoring the algorithm
- a function to insert in to a sorted list
- a sorting function that repeatedly inserts

Insert function ---- insert x into sorted list xs

	let rec insert (x:int) (xs: int list) : int list =
		match xs with
		| [] -> [x]
		| hd :: t1 ->
			if hd < x then
				hd :: insert x t1 (* build a new list with hd at the beginning *)
			else
				x :: xs
	;;

Insertion sort function ---- Given a list, return the sorted list

	type il = int list

	insert : int -> il -> il

	let rec insert_sort (xs : il) : il =
	
		let rec aux (sorted : il) (unsorted : il) : il =
			match unsorted with
			| [] -> sorted 
			| hd :: t1 -> aux (insert hd sorted) t1
	    in
		aux [] xs
		
	;;
