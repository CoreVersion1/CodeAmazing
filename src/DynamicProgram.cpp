#include <iostream>
#include <vector>

class Solution {
 public:
  // 自顶向下
  int DP_Fib(int n)
  {
    if (n == 0 || n == 1)
    {
      return n;
    }

    if (target_[n] != -1)
    {
      return target_[n];
    }

    target_[n] = DP_Fib(n - 1) + DP_Fib(n - 2);

    return target_[n];
  }

  // 自底向上
  int DP_Fib2(int n)
  {
    if (n <= 1)
    {
      return n;
    }

    target_[0] = 0;
    target_[1] = 1;

    for (int i = 2; i <= n; i++)
    {
      target_[i] = target_[i - 1] + target_[i - 2];
    }
    return target_[n];
  }

  // 求斐波那契数
  int fib(int n)
  {
    target_.reserve(n + 1);
    target_.assign(n + 1, -1);

    return DP_Fib2(n);
  }

 private:
  std::vector<int> target_ = {};
};
