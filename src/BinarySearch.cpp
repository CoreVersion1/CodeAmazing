#include <vector>
#include <iostream>

// 基本二分查找
int BinarySearch(const std::vector<int>& nums, int target)
{
  int left  = 0;
  int right = nums.size() - 1;

  for (; left <= right;)
  {
    auto mid = left + (right - left) / 2;

    if (nums[mid] == target)
    {
      return mid;
    }
    else if (nums[mid] > target)
    {
      right = mid - 1;
    }
    else if (nums[mid] < target)
    {
      left = mid + 1;
    }
  }
  return -1;
}

// 二分查找-左边界
int LeftBound(const std::vector<int>& nums, int target)
{
  int left  = 0;
  int right = nums.size() - 1;

  for (; left <= right;)
  {
    auto mid = left + (right - left) / 2;

    if (nums[mid] == target)
    {
      right = mid - 1;
    }
    else if (nums[mid] > target)
    {
      right = mid - 1;
    }
    else if (nums[mid] < target)
    {
      left = mid + 1;
    }
  }

  if (left < 0 || left >= nums.size() || nums[left] != target)
  {
    return -1;
  }

  return left;
}

// 二分查找-右边界
int RightBound(const std::vector<int>& nums, int target)
{
  int left  = 0;
  int right = nums.size() - 1;

  for (; left <= right;)
  {
    auto mid = left + (right - left) / 2;

    if (nums[mid] == target)
    {
      left = mid + 1;
    }
    else if (nums[mid] > target)
    {
      right = mid - 1;
    }
    else if (nums[mid] < target)
    {
      left = mid + 1;
    }
  }

  if (right < 0 || right >= nums.size() || nums[right] != target)
  {
    return -1;
  }

  return right;
}
