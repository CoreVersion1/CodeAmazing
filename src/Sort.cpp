#include <iostream>
#include <map>
#include <vector>
#include <algorithm>

class Solution {
 public:
  void PrintVector(const std::vector<int> &nums)
  {
    std::cout << std::endl;
    for (const auto &num : nums)
    {
      std::cout << num << " ";
    }
    std::cout << std::endl;
  }

  // 选择排序
  // 时间复杂度O(n^2)，空间复杂度O(1)，不稳定的排序
  // [0,i)为有序区间
  void Sort_Select(std::vector<int> &nums)
  {
    for (int i = 0; i < nums.size(); i++)
    {
      for (int j = i + 1; j < nums.size(); j++)
      {
        if (nums[i] > nums[j])
        {
          std::swap(nums[i], nums[j]);
        }
      }
    }

    return;
  }

  // 冒泡排序
  // 时间复杂度O(n^2)，空间复杂度O(1)，稳定的排序
  // [0,i)为有序区间
  void Sort_Bubble(std::vector<int> &nums)
  {
    for (int i = 0; i < nums.size(); i++)
    {
      bool swapped = false;  // 交换的标记

      // 倒序冒泡，相邻项之间两两比较，找到最小项
      for (int j = nums.size() - 1; j > i; j--)
      {
        if (nums[j - 1] > nums[j])
        {
          std::swap(nums[j - 1], nums[j]);
          swapped = true;  // 发生了交换
        }
      }

      // 一次交换都没有发生，说明已经有序，可以提前终止
      if (!swapped)
      {
        break;
      }
    }

    return;
  }

  // 插入排序
  // 时间复杂度O(n^2)，空间复杂度O(1)，稳定的排序
  // [0,i)为有序区间
  void Sort_Insert(std::vector<int> &nums)
  {
    for (int i = 0; i < nums.size(); i++)
    {
      for (int j = i; j > 0; j--)  // 将nums[i]插入到有序区间[0,i)
      {
        if (nums[j - 1] > nums[j])
        {
          std::swap(nums[j - 1], nums[j]);
        }
        else
        {
          break;
        }
      }
    }

    return;
  }

  // 希尔排序
  // 时间复杂度小于O(n^2)，空间复杂度O(1)，不稳定的排序
  // [0,i)为有序区间，且间隔为gap
  void Sort_Shell(std::vector<int> &nums)
  {
    for (int gap = nums.size() / 2; gap >= 1; gap /= 2)
    {
      for (int i = gap; i < nums.size(); i++)
      {
        for (int j = i; j >= gap; j -= gap)
        {
          if (nums[j - gap] > nums[j])
          {
            std::swap(nums[j - gap], nums[j]);
          }
          else
          {
            break;
          }
        }
      }
    }
  }
};

int main(void)
{
  const std::vector<int> nums = {10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0};
  std::vector<int> nums_tmp{};
  Solution s{};

  nums_tmp = nums;
  s.Sort_Select(nums_tmp);
  s.PrintVector(nums_tmp);

  nums_tmp = nums;
  s.Sort_Bubble(nums_tmp);
  s.PrintVector(nums_tmp);

  nums_tmp = nums;
  s.Sort_Insert(nums_tmp);
  s.PrintVector(nums_tmp);

  nums_tmp = nums;
  s.Sort_Shell(nums_tmp);
  s.PrintVector(nums_tmp);

  return 0;
}
