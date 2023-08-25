---
layout: post
title: "Getting Java Event Notification Right"
date: 2015-03-28 01:14:55 +0800
comments: true
categories: Java
---
> 本文由 [林申](http://weibo.com/linshen2011) 译自 [Getting Java Event Notification Right](http://www.javacodegeeks.com/2015/03/getting-java-event-notification-right.html)，并由 [唐尤华](http://weibo.com/tangyouhua) 校稿，首次发布在 [ImportNew](http://www.importnew.com/15446.html)，__转载请务必注明出处__！

很多情况下你会定义一类事件，然后对其进行管理。然而，处理不当就会遇到 `ConcurrentModificationException`。本文通过示例介绍了使用 Java 事件通知（Event Notification）需要注意的一些细节。

通过实现观察者模式来提供 Java 事件通知（Java event notification）似乎不是件什么难事儿，但这过程中也很容易就掉进一些陷阱。本文介绍了我自己在各种情形下，不小心制造的一些常见错误。

Java 事件通知
===

让我们从一个最简单的 Java Bean 开始，它叫 `StateHolder`，里面封装了一个私有的 `int` 型属性 `state` 和常见的访问方法：

``` java
public class StateHolder {
 
  private int state;
 
  public int getState() {
    return state;
  }
 
  public void setState( int state ) {
    this.state = state;
  }
}
```
现在假设我们决定要 Java bean 给已注册的观察者广播一条 状态已改变 事件。小菜一碟！！！定义一个最简单的事件和监听器简直撸起袖子就来……

``` java
// change event to broadcast
public class StateEvent {
 
  public final int oldState;
  public final int newState;
 
  StateEvent( int oldState, int newState ) {
    this.oldState = oldState;
    this.newState = newState;
  }
}
 
// observer interface
public interface StateListener {
  void stateChanged( StateEvent event );
}
```

…接下来我们需要在 `StateHolder` 的实例里注册 `StatListeners` …

```
public class StateHolder {
 
  private final Set<StateListener> listeners = new HashSet<>();
 
  [...]
 
  public void addStateListener( StateListener listener ) {
    listeners.add( listener );
  }
 
  public void removeStateListener( StateListener listener ) {
    listeners.remove( listener );
  }
}
```

…最后一个要点，需要调整一下 `StateHolder#setState` 这个方法，来确保每次状态有变时发出的通知，都代表这个状态真的相对于上次产生变化了：

```
public void setState( int state ) {
  int oldState = this.state;
  this.state = state;
  if( oldState != state ) {
    broadcast( new StateEvent( oldState, state ) );
  }
}
 
private void broadcast( StateEvent stateEvent ) {
  for( StateListener listener : listeners ) {
    listener.stateChanged( stateEvent );
  }
}
```
搞定了！要的就是这些。为了显得专(zhuang)业(bi)一点，我们可能还甚至为此实现了测试驱动，并为严密的代码覆盖率和那根表示测试通过的小绿条而洋洋自得。而且不管怎么样，这不就是我从网上那些教程里面学来的写法吗？

那么问题来了：这个解决办法是有缺陷的。。。

<!-- more -->

并发修改
===

像上面那样写 `StateHolder` 很容易遇到并发修改异常（`ConcurrentModificationException`），即使仅仅限制在一个单线程里面用也不例外。但究竟是谁导致了这个异常，它又为什么会发生呢？

``` 
java.util.ConcurrentModificationException
    at java.util.HashMap$HashIterator.nextNode(HashMap.java:1429)
    at java.util.HashMap$KeyIterator.next(HashMap.java:1453)
    at com.codeaffine.events.StateProvider.broadcast(StateProvider.java:60)
    at com.codeaffine.events.StateProvider.setState(StateProvider.java:55)
    at com.codeaffine.events.StateProvider.main(StateProvider.java:122)
```

乍一看这个错误堆栈包含的信息，异常是由我们用到的一个 `HashMap` 的 `Iterator` 抛出的，可在我们的代码里没有用到任何的迭代器，不是吗？好吧，其实我们用到了。要知道，写在 `broadcast` 方法里的 `for each` 结构，实际上在编译时是会被转变成一个迭代循环的。

因为在事件广播过程中，如果一个监听器试图从 `StateHolder` 实例里面把自己移除，就有可能导致 `ConcurrentModificationException`。所以比起在原先的数据结构上进行操作，有一个解决办法就是我们可以在这组监听器的快照（snapshot）上进行迭代循环。

这样一来，“移除监听器”这一操作就不会再干扰事件广播机制了（但要注意的是通知还是会有轻微的语义变化，因为当 `broadcast` 方法被执行的时候，这样的移除操作并不会被快照体现出来）：

```
private void broadcast( StateEvent stateEvent ) {
  Set<StateListener> snapshot = new HashSet<>( listeners );
  for( StateListener listener : snapshot ) {
    listener.stateChanged( stateEvent );
  }
}
```

但是，如果 `StateHolder` 被用在一个多线程的环境里呢？

同步
===


要再多线程的环境里使用 `StateHolder` ，它就必须是线程安全的。不过这也很容易实现，给我们类里面的每个方法加上 `synchronized` 就搞定了，不是吗？

```
public class StateHolder {
  public synchronized void addStateListener( StateListener listener ) {  [...]
  public synchronized void removeStateListener( StateListener listener ) {  [...]
  public synchronized int getState() {  [...]
  public synchronized void setState( int state ) {  [...]
```

现在我们读写操作 一个 `StateHolder` 实例的时候都有了 内置锁(Intrinsic Lock) 做保证，这使得公有方法具有了原子性，也确保了正确的状态对不同的线程都可见。任务完成！

才怪…尽管这样的实现是线程安全的，但一旦程序要调用它，就需要承担死锁的风险。

设想一下如下这种情形：线程 A 改变了 `StateHolder` 的状态 S，在向各个监听器（listener）广播这个状态 S 的时候，线程 B 视图访问状态 S ，然后被阻塞。如果 B 持有了一个对象的同步锁，这个对象又是关于状态 S的，并且本来是要广播给众多监听器当中的某一个的，这种情况下我们就会遇到一个死锁。

这就是为什么我们要缩小状态访问的同步性，在一个“保护通道”里面来广播这个事件：

```
public class StateHolder {
 
  private final Set<StateListener> listeners = new HashSet<>();
  private int state;
 
  public void addStateListener( StateListener listener ) {
    synchronized( listeners ) {
      listeners.add( listener );
    }
  }
 
  public void removeStateListener( StateListener listener ) {
    synchronized( listeners ) {
      listeners.remove( listener );
    }
  }
 
  public int getState() {
    synchronized( listeners ) {
      return state;
    }
  }
 
  public void setState( int state ) {
    int oldState = this.state;
    synchronized( listeners ) {
      this.state = state;
    }
    if( oldState != state ) {
      broadcast( new StateEvent( oldState, state ) );
    }
  }
 
  private void broadcast( StateEvent stateEvent ) {
    Set<StateListener> snapshot;
    synchronized( listeners ) {
      snapshot = new HashSet<>( listeners );
    }
    for( StateListener listener : snapshot ) {
      listener.stateChanged( stateEvent );
    }
  }
}
```

上面这段代码是在之前的基础上稍加改进来实现的，通过使用 Set 实例作为内部锁来提供合适（但也有些过时）的同步性，监听者的通知事件在保护块之外发生，这样就避免了一种死等的可能。

> 注意: 由于系统并发操作的天性，这个解决方案并不能保证变化通知按照他们产生的顺序依次到达监听器。如果观察者一侧对实际状态的准确性有较高要求，可以考虑把 `StateHolder` 作为你事件对象的来源。

> 如果事件顺序这在你的程序里显得至关重要，有一个办法就是可以考虑用一个线程安全的先入先出（FIFO）结构，连同监听器的快照一起，在 `setState` 方法的保护块里缓冲你的对象。只要 `FIFO` 结构不是空的，一个独立的线程就可以从一个不受保护的区域块里触发实际事件（生产者-消费者模式），这样理论上就可以不必冒着死锁的危险还能确保一切按照时间顺序进行。我说理论上，是因为到目前为止我也还没亲自这么试过。。

鉴于前面已经实现的，我们可以用诸如 `CopyOnWriteArraySet` 和 `AtomicInteger` 来写我们的这个线程安全类，从而使这个解决方案不至于那么复杂：

```
public class StateHolder {
 
  private final Set<StateListener> listeners = new CopyOnWriteArraySet<>();
  private final AtomicInteger state = new AtomicInteger();
 
  public void addStateListener( StateListener listener ) {
    listeners.add( listener );
  }
 
  public void removeStateListener( StateListener listener ) {
    listeners.remove( listener );
  }
 
  public int getState() {
    return state.get();
  }
 
  public void setState( int state ) {
    int oldState = this.state.getAndSet( state );
    if( oldState != state ) {
      broadcast( new StateEvent( oldState, state ) );
    }
  }
 
  private void broadcast( StateEvent stateEvent ) {
    for( StateListener listener : listeners ) {
      listener.stateChanged( stateEvent );
    }
  }
}

```
既然 `CopyOnWriteArraySet` 和 `AtomicInteger` 已经是线程安全的了，我们不再需要上面提到的那样一个“保护块”。但是等一下！我们刚刚不是在学到应该用一个快照来广播事件，来替代用一个隐形的迭代器在原集合（Set）里面做循环嘛？

这或许有些绕脑子，但是由 `CopyOnWriteArraySet` 提供的 Iterator（迭代器）里面已经有了一个“快照“。`CopyOnWriteXXX` 这样的集合就是被特别设计在这种情况下大显身手的——它在小长度的场景下会很高效，而针对频繁迭代和只有少量内容修改的场景也做了优化。这就意味着我们的代码是安全的。

随着 Java 8 的发布，`broadcast` 方法可以因为 `Iterable#forEach` 和 lambdas 表达式的结合使用而变得更加简洁，代码当然也是同样安全，因为迭代依然表现为在“快照”中进行：

```
private void broadcast( StateEvent stateEvent ) {
  listeners.forEach( listener -> listener.stateChanged( stateEvent ) );
}
```

异常处理
===

本文的最后介绍了如何处理抛出 `RuntimeExceptions` 的那些损坏的监听器。尽管我总是严格对待 fail-fast 错误机制，但在这种情况下让这个异常得不到处理是不合适的。尤其考虑到这种实现经常在一些多线程环境里被用到。

损坏的监听器会有两种方式来破坏系统：第一，它会阻止通知向观察者的传达过程；第二，它会伤害那些没有准备处理好这类问题的调用线程。总而言之它能够导致多种莫名其妙的故障，并且有的还难以追溯其原因，

因此，把每一个通知区域用一个 `try-catch` 块来保护起来会显得比较有用。

```
private void broadcast( StateEvent stateEvent ) {
  listeners.forEach( listener -> notifySafely( stateEvent, listener ) );
}
 
private void notifySafely( StateEvent stateEvent, StateListener listener ) {
  try {
    listener.stateChanged( stateEvent );
  } catch( RuntimeException unexpected ) {
    
// appropriate exception handling goes here...
  }
}
```

总结
===

综上所述，Java 的事件通知里面有一些基本要点你还是必须得记住的。在事件通知过程中，要确保在监听器集合的快照里做迭代，保证事件通知在同步块之外，并且在合适的时候再安全地通知监听器。

但愿我写的这些让你觉得通俗易懂，最起码尤其在并发这一节不要再被搞得一头雾水。如果你发现了文章中的错误或者有其它的点子想分享，尽管在文章下面的评论里告诉我吧。