# Buffer ownership

The resizer bounds memory use and keeps retained results unchanged.

## GPU work and input lifetime

One ``GPUResizer`` belongs to one serial caller queue.
Each resize submits one Metal command buffer and waits for completion before returning.
The resizer retains the source pixel buffer and its Core Video texture wrappers until completion.
The shader samples Core Video textures directly, without a CPU copy of the input.

The output is a shared Metal buffer. CPU reads can start when `resize` returns.
The source Frame can be disposed at that point because the output owns a separate allocation.
The resizer reuses its command queue, texture cache, compute pipeline, and available output buffers.

## Bounded output storage

``GPUResizer/init(options:maximumOutstandingResults:)`` defaults to three outstanding results.
Each result holds an exclusive lease on one pool buffer.
The pool allocates buffers lazily, up to its configured capacity, then reuses released buffers.
When all slots are retained, resize throws ``GPUResizerError/outputCapacityExceeded`` without waiting for a result to be released.

One allocation uses `width * height * 3 * dataType.bytesPerChannel` bytes.
The maximum output allocation is that size multiplied by `maximumOutstandingResults`.
Metal, Core Video, and the installed shaders also use driver-managed resources.

ARC returns a slot to the pool when its ``GPUResizeResult`` is deallocated.
A retained result remains readable after the source Frame and the resizer are released.
Result release can occur on a different queue. A small lock protects the pool's free-list during release and acquisition.

## Scoped native access

The pointer in ``GPUResizeResult/withUnsafeBytes(_:)`` cannot escape its closure.
Copy into `Data` within the closure when you need independent CPU storage.
The resizer does not recycle that result's buffer while the closure is running, including when the closure throws.

Treat the buffer in ``GPUResizeResult/withMetalBuffer(_:)`` as read-only.
Retaining the native `MTLBuffer` alone does not retain the pool lease.
Capture the result in your command buffer's completion handler when you submit asynchronous Metal work.

```swift
result.withMetalBuffer { buffer in
	encoder.setBuffer(buffer, offset: 0, index: 0)
	// Encode your reads and finish encoding here.
	commandBuffer.addCompletedHandler { [result] _ in
		withExtendedLifetime(result) {}
	}
	commandBuffer.commit()
}
```

Your code owns `encoder` and `commandBuffer` in this example.
Keep outstanding downstream commands within the result pool's capacity.
Metal retaining a buffer keeps the allocation alive but does not prevent the pool from reusing its bytes after you release its result.
