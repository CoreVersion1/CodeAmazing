#include <iostream>
#include <vector>
#include <string>
#include <sstream>

// 单链表节点
class ListNode {
 public:
  ListNode(int x) : val(x), next(nullptr) {}

 public:
  int val        = {};
  ListNode* next = {};
};

class Solution {
 public:
  // 数组创建链表
  ListNode* CreateList(const std::vector<int>& arr)
  {
    if (arr.empty())
    {
      return nullptr;
    }

    auto* head = new ListNode(arr[0]);
    auto* cur  = head;

    for (int i = 1; i < arr.size(); ++i)
    {
      cur->next = new ListNode(arr[i]);
      cur       = cur->next;
    }
    return head;
  }

  // 释放链表
  void FreeList(ListNode*& head)
  {
    while (head != nullptr)
    {
      auto* temp = head;
      head       = head->next;
      delete temp;
    }
    return;
  }

  // 遍历链表
  std::string TraverseList(ListNode* head)
  {
    std::ostringstream oss;

    oss << "{";
    for (auto cur = head; cur != nullptr; cur = cur->next)
    {
      oss << cur->val;

      if (cur->next != nullptr)
      {
        oss << ",";
      }
    }
    oss << "}";

    return oss.str();
  }

  // 头部添加节点
  ListNode* AddHead(ListNode* head, int val)
  {
    auto* new_node = new ListNode(val);
    new_node->next = head;
    head           = new_node;
    return head;
  }

  // 尾部添加节点
  ListNode* AddTail(ListNode* head, int val)
  {
    // 找到前驱节点
    auto* cur = head;
    while (cur->next != nullptr)
    {
      cur = cur->next;
    }

    auto* new_node = new ListNode(val);
    cur->next      = new_node;
    return head;
  }

  // 中间插入节点
  ListNode* AddMid(ListNode* head, int val, int pos)
  {
    ListNode** curr = &head;  // 使用二级指针直接修改指向

    // 遍历到目标位置的前驱节点
    for (int i = 0; i < pos; ++i)
    {
      if (*curr == nullptr)
      {
        std::cout << "Invalid position" << std::endl;
        return head;  // 位置超界
      }
      curr = &((*curr)->next);
    }

    // 创建并插入新节点
    auto* new_node = new ListNode(val);
    new_node->next = *curr;
    *curr          = new_node;

    return head;
  }

  // 删除节点
  ListNode* DelNode_Index(ListNode* head, int idx)
  {
    ListNode** curr = &head;

    // 找到前驱节点
    for (int i = 0; i < idx; ++i)
    {
      if (*curr == nullptr)
      {
        std::cout << "Invalid index: " << idx << std::endl;
        return head;  // 索引超界
      }
      curr = &((*curr)->next);
    }

    if (*curr == nullptr)
    {
      std::cout << "Invalid index: " << idx << std::endl;
      return head;  // 无节点可删除
    }

    ListNode* temp = *curr;
    *curr          = (*curr)->next;  // 删除当前节点
    delete temp;

    return head;
  }

  // 删除头部节点
  ListNode* DelHead(ListNode* head)
  {
    if (head == nullptr)
    {
      return head;
    }

    auto* new_head = head->next;
    delete head;
    return new_head;
  }

  // 删除尾部节点
  ListNode* DelTail(ListNode* head)
  {
    if (head == nullptr)
    {
      return head;
    }

    ListNode** curr = &head;

    // 遍历到最后一个节点的前驱
    while ((*curr)->next != nullptr)
    {
      curr = &((*curr)->next);
    }

    // 删除尾节点
    delete *curr;
    *curr = nullptr;

    return head;
  }

  typedef bool (*match_fn)(const ListNode*);
  // 删除所有满足条件的节点
  // 优化版，参考链接：https://coolshell.cn/articles/8990.html
  ListNode* RemoveIf(ListNode* head, match_fn match)
  {
    if (match == nullptr)
    {
      return head;
    }

    ListNode** curr = &head;  // 二级指针，方便处理头节点
    while (*curr != nullptr)
    {
      // std::cout << "*curr = " << (*curr) << ", head = " << head << std::endl;

      ListNode* tmp = *curr;

      if (match(tmp))
      {
        *curr = (*curr)->next;  //! 重点！ 删除当前节点
        delete tmp;
      }
      else
      {
        curr = &((*curr)->next);  //! 重点！ 指向下一个节点的指针
      }
    }

    // 传入的head指针是局部变量
    // 要返回可能更新后的head指针
    return head;
  }

  ListNode* Reverse(ListNode* head)
  {
    ListNode* prev = nullptr;
    ListNode* curr = head;
    ListNode* next = nullptr;

    while (curr != nullptr)
    {
      next = curr->next;

      // 反转
      curr->next = prev;

      prev = curr;
      curr = next;
    }

    // 返回反转后的头节点
    return prev;
  }
};

int main(void)
{
  Solution sol{};

  std::vector<int> nums = {1, 2, 3, 4, 5};
  auto* head            = sol.CreateList(nums);
  std::cout << "CreateList: " << sol.TraverseList(head) << std::endl;

  head = sol.AddHead(head, 0);
  std::cout << "AddHead: " << sol.TraverseList(head) << std::endl;

  head = sol.AddTail(head, 6);
  std::cout << "AddTail: " << sol.TraverseList(head) << std::endl;

  head = sol.AddMid(head, 7, 3);
  std::cout << "AddMid: " << sol.TraverseList(head) << std::endl;

  head = sol.DelNode_Index(head, 3);
  std::cout << "DelNode: " << sol.TraverseList(head) << std::endl;

  head = sol.DelHead(head);
  std::cout << "DelHead: " << sol.TraverseList(head) << std::endl;

  head = sol.DelTail(head);
  std::cout << "DelTail: " << sol.TraverseList(head) << std::endl;

  head = sol.RemoveIf(head, [](const ListNode* node) { return node->val % 2 == 1; });
  std::cout << "RemoveIf: " << sol.TraverseList(head) << std::endl;

  head = sol.Reverse(head);
  std::cout << "Reverse: " << sol.TraverseList(head) << std::endl;

  sol.FreeList(head);
  std::cout << "FreeList: " << sol.TraverseList(head) << std::endl;

  return 0;
}
