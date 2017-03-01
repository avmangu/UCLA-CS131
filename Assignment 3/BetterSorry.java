import java.util.concurrent.atomic.AtomicIntegerArray;

class BetterSorry implements State
{
	//	Private varibles and helper function
	private AtomicIntegerArray value;
	private byte maxval;
	private void copyOperator(byte[] v)
	{
		int len = v.length;
		value = new AtomicIntegerArray(len);
		for (int i = 0; i < len; i++)
			value.set(i, v[i]);
	}

	BetterSorry(byte[] v)
	{
		copyOperator(v);
		maxval = 127;
	}
	BetterSorry(byte[] v, byte m)
	{
		copyOperator(v);
		maxval = m;
	}

	public int size() {	return value.length(); }

	public byte[] current()
	{
		byte[] result = new byte[size()];
		for (int i = 0; i < size(); i++)
			result[i] = (byte) value.get(i);
		return result;
	}

	public boolean swap(int i, int j)
	{
		if (value.get(i) <=0 || value.get(j) >= maxval)
			return false;
		value.getAndDecrement(i);
		value.getAndIncrement(j);
		return true;
	}
}