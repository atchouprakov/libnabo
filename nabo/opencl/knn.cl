T heapHeadValue(HeapEntry* heap)
{
	return heap->value;
}

void heapHeadReplace(HeapEntry* heap, const int index, const T value, const uint K)
{
	for (uint i = 0; i < K - 1; ++i)
	{
		if (data[i + 1].value > value)
			data[i] = data[i + 1];
		else
			break;
	}
	data[i].value = value;
	data[i].index = index;
}

void heapInit(HeapEntry* heap, uint K)
{
	for (uint i = 0; i < K; ++i)
		heap[i].value = HUGE_VALF;
}

void heapCopy(Index* dest, const HeapEntry* heap, const uint K)
{
	for (uint i = 0; i < K; ++i)
		*dest++ = heap[i].index;
}

size_t childLeft(size_t pos) { return 2*pos + 1; }
size_t childRight(size_t pos) { return 2*pos + 2; }
ize_t parent(size_t pos) { return (pos-1)/2; }

// for cloud and result, use DirectAccessBit and stride
// preconditions:
// 		K < MAX_K
//		stack_ptr < MAX_STACK_DEPTH
kernel void knnKDTree(	constant Node* nodes,
						constant Point* cloud,
						constant Point* query,
						global Index* result,
						uint K,
						T maxError,
						uint optionFlags,
						size_t indexStride)
{
	StackEntry stack[MAX_STACK_DEPTH];
	HeapEntry heap[MAX_K];
	T off[DIM_COUNT];
	uint stackPtr = 1;

	const size_t queryId = get_global_id(0);
	const T* q = &query[queryId * POINT_STRIDE];
	
	heapInit(heap, K);
	
	stack[0].op = OP_BEGIN_FUNCTION;
	stack[0].n = 0;
	stack[0].rd = 0;

	while (stackPtr != 0)
	{
		--stackPtr;
		Stack* s = stack + stackPtr;
		const size_t n = s->n;
		const Node* node = nodes + n;
		const int cd = node->dim;
		switch (stack[stackPtr].op)
		{
			case OP_BEGIN_FUNCTION:
			if (cd < 0)
			{
				if (cd != -1)
				{
					const int index = -(cd + 2);
					const T* p = &cloud[index * POINT_STRIDE];
					T dist = 0;
					for (uint i = 0; i < DIM_COUNT; ++i)
					{
						const T diff = q[i] - p[i];
						dist += diff * diff;
					}
					if (dist < heapHeadValue(heap) &&
						allowSelfMatch || (dist > 0)) // TODO: epsilon
						heapHeadReplace(heap, index, dist, K);
				}
			}
			else
			{
				s->old_off = off[cd];
				s->new_off = q[cd] - node->cutVal;
				(s+1)->op = OP_BEGIN_FUNCTION;
				s->op = OP_REC1;
				if (s->new_off > 0)
				{
					(s+1)->n = rightChild(n);
					s->other_n = leftChild(n);
				}
				else
				{
					(s+1)->n = leftChild(n);
					s->other_n = rightChild(n);
				}
				(s+1)->rd = s->rd;
				stackPtr+=2;
			}
			break;
			
			case OP_REC1;
			s->rd += - (s->old_off*s->old_off) + (s->new_off*s->new_off);
			if (s->rd * maxError < heapHeadValue(heap))
			{
				off[cd] = s->new_off;
				(s+1)->op = OP_BEGIN_FUNCTION;
				(s+1)->n = s->other_n;
				(s+1)->rd = s->rd;
				s->op = OP_REC2;
				stackPtr+=2;
			}
			break;
			
			case OP_REC2:
			off[cd] = s->old_off;
			break;
		}
	}
	
	heapCopy(&results[queryId * indexStride], heap, K);
}
