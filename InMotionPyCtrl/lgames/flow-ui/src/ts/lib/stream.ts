import * as stream from 'mithril/stream'
import {Stream} from 'mithril/stream'

export interface Lift {
	<A,Z>(fn: (a: A) => Z, s: Stream<A>): Stream<Z>
	<A,B,Z>(fn: (a: A, b: B) => Z, sa: Stream<A>, sb: Stream<B>): Stream<Z>
	<A,B,C,Z>(fn: (a: A, b: B, c: C) => Z, sa: Stream<A>, sb: Stream<B>, sc: Stream<C>): Stream<Z>
	<A,B,C,D,Z>(fn: (a: A, b: B, c: C, d: D) => Z, sa: Stream<A>, sb: Stream<B>, sc: Stream<C>, sd: Stream<D>): Stream<Z>
	<A,B,C,D,E,Z>(fn: (a: A, b: B, c: C, d: D, e: E) => Z, sa: Stream<A>, sb: Stream<B>, sc: Stream<C>, sd: Stream<D>, se: Stream<E>): Stream<Z>
	(fn: (...values: any[]) => any, ...streams: Stream<any>[]): Stream<any>
}

export const lift: Lift = function lift (fn: (...values: any[]) => any, ...streams: Stream<any>[]) {
	return stream.merge(streams).map(s => fn.apply(undefined, s))
}
