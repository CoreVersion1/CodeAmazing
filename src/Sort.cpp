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

  // 快速排序的分区函数：将小于基准项的项放在基准左边，大于基准项的项放在基准右边
  int Partition(std::vector<int> &nums, int low, int high)
  {
    int pivot = nums[high];  // 以最后一项为基准
    int i     = low - 1;     // i 为小于基准项的最后一项的索引

    for (int j = low; j < high; j++)
    {
      if (nums[j] < pivot)
      {
        i++;
        std::swap(nums[i], nums[j]);  // 将小于基准项的项放在基准左边
      }
    }

    std::swap(nums[i + 1], nums[high]);  // 将基准项放在正确的位置
    return i + 1;                        // 返回基准项的索引
  }

  // 快速排序
  // 时间复杂度O(nlogn)，空间复杂度O(logn)，不稳定的排序
  void Sort_Quick(std::vector<int> &nums, int low, int high)
  {
    if (low >= high)  // 递归终止条件
    {
      return;
    }

    int pivot = Partition(nums, low, high);
    Sort_Quick(nums, low, pivot - 1);
    Sort_Quick(nums, pivot + 1, high);
  }

  // 快速排序
  // 时间复杂度O(nlogn)，空间复杂度O(logn)，不稳定的排序
  void Sort_Quick(std::vector<int> &nums)
  {
    Sort_Quick(nums, 0, nums.size() - 1);
  }

  // 归并函数，将两个有序区间合并
  void Merge(std::vector<int> &nums, int left, int mid, int right)
  {
    int i = left;
    int j = mid + 1;
    std::vector<int> tmp{};

    // 合并两个有序区间
    while (i <= mid && j <= right)
    {
      if (nums[i] < nums[j])
      {
        tmp.push_back(nums[i++]);
      }
      else
      {
        tmp.push_back(nums[j++]);
      }
    }

    // 将剩余项添加到tmp
    while (i <= mid)
    {
      tmp.push_back(nums[i++]);
    }
    while (j <= right)
    {
      tmp.push_back(nums[j++]);
    }

    // 将tmp拷贝到nums
    for (int k = 0; k < tmp.size(); k++)
    {
      nums[left + k] = tmp[k];
    }
  }

  // 归并排序
  // 时间复杂度O(nlogn)，空间复杂度O(n)，稳定的排序
  void Sort_Merge(std::vector<int> &nums, int left, int right)
  {
    if (left >= right)  // 递归终止条件
    {
      return;
    }

    int mid = (left + right) / 2;      // 找到中间项
    Sort_Merge(nums, left, mid);       // 排序左边
    Sort_Merge(nums, mid + 1, right);  // 排序右边
    Merge(nums, left, mid, right);     // 合并
  }

  // 归并排序
  // 时间复杂度O(nlogn)，空间复杂度O(n)，稳定的排序
  void Sort_Merge(std::vector<int> &nums)
  {
    Sort_Merge(nums, 0, nums.size() - 1);
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
