
local constants = require 'constants'
local colors = require 'colors'
local utils = require 'utils'
local themeManager = require 'theme-manager'
local images = require 'images'
local timer = require 'timer'

local listManager = {}
local lineHeight = _G.font:getHeight() + 1

listManager.pageSize = (_G.currentTheme and _G.currentTheme.pageSize) or constants.PAGE_SIZE
listManager.listBounds = {
  x = 24,
  y = 24,
  w = constants.CANVAS_WIDTH - 120,
  h = constants.CANVAS_HEIGHT - 48
}
listManager.rightSideX = listManager.listBounds.x + listManager.listBounds.w
listManager.rightSideY = listManager.listBounds.y

local function getListStencil()
  local rec = listManager.listBounds
  return function ()
    love.graphics.rectangle('fill', rec.x, rec.y, rec.w, rec.h)
  end
end

-- for lines that are too large to fit
local clippedLineX = 0
local clippedLineSpeed = 60
local clippedLineDirection = -1
local clippedLineOffset = 0
local clippedLineReturnDelay = 0.5

-- bounce line left and right
-- function listManager:moveClippedLine(x)
--   self.clippetTextTween = _G.flux.to(
--     self, 2, { clippedLineX = x })
--   :oncomplete(function ()
--     if clippedLineX < 0 then
--       self:moveClippedLine(0)
--     else
--       self:moveClippedLine(-self.clippedLineOffset)
--     end
--   end):ease('linear'):delay(0.5)
-- end

function listManager:resetClippedLine()
  local item = self:getSelectedItem()
  if not item.clipped then return end
  clippedLineOffset = _G.font:getWidth(item.displayLabel) - self.listBounds.w

  -- if self.clippetTextTween then
  --   self.clippetTextTween:stop()
  --   clippedLineX = 0
  -- end

  -- self:moveClippedLine(-self.clippedLineOffset)

  clippedLineX = 0
  clippedLineDirection = -1
  self.moveClippedLine = false
  timer.new('moveClippedLine', clippedLineReturnDelay, 1)
end

function listManager:getListingCommons()
  local list = self.currentList

  local from = 1 + (list.page.pageNumber - 1) * self.pageSize
  local to = from + self.pageSize - 1
  local y = 0

  return list, from, to, y
end

function listManager:getPaginationCommons()
  local list = self.currentList
  local n = #list.items
  local totalPages = math.ceil(n / self.pageSize)

  return list, n, totalPages
end

function listManager:drawIconAndGetOffset(icon, x, y)
  local iconOffset = 0
  if icon then
    love.graphics.setColor(colors.white)
    iconOffset = icon:getWidth() + 5
    utils.drawWithShadow(icon,
      self.listBounds.x + x,
      self.listBounds.y + y * lineHeight
    )
  end

  return iconOffset
end

function listManager:printItemText(item, iconOffset, x, y)
  local list, _, _, _ = self:getListingCommons()
  local label = constants.systemsLabels[item.internalLabel] or item.displayLabel
  local color = (item.isDir and colors.blue) or
    (item.color or list.color or colors.white)
  label = label or '<label not set>'

  utils.pp(label,
    self.listBounds.x + iconOffset + x,
    self.listBounds.y + y * lineHeight,
    { fgColor = color }
  )

end

function listManager:drawListPointer(y)
  local list, _, _, _ = self:getListingCommons()
  local p = images.icons.defaultPointer
  local offset = p:getWidth() + constants.POINTER_SEPARATION
  if y == (list.page.indexAtCurrentPage - 1) then
    love.graphics.setColor(colors.white)
    utils.drawWithShadow(images.icons.defaultPointer,
      self.listBounds.x - offset,
      self.listBounds.y + y * lineHeight
    )
  end
end

function listManager:drawLineExtras(item, y)
  if item.checkbox then
    local icon = images.icons.checkboxOff
    if item.value then icon = images.icons.checkboxOn end
    utils.drawWithShadow(icon,
      self.rightSideX,
      self.rightSideY + y * lineHeight
    )
  end
end

function listManager:setCurrentList(list)
  self.currentList = list
end

function listManager:getTotalPages()
  return math.ceil(#self.currentList.items / self.pageSize)
end

function listManager:getItemsAtCurrentPage()
  local totalPages = self:getTotalPages()
  local _, n, _ = self:getPaginationCommons()
  return self.pageSize - ((totalPages * self.pageSize) - n)
end

function listManager:getSelectedItem()
  if not self.currentList then return end
  local list = self.currentList
  return list.items[list.index]
end

function listManager:invertClippedLineMovement()
  clippedLineDirection = clippedLineDirection * -1
  self.moveClippedLine = false
  timer.new('moveClippedLine', clippedLineReturnDelay)
end

function listManager:update(dt)
  --_G.flux.update(dt)
  if timer.isTimeTo('moveClippedLine', dt) then
    self.moveClippedLine = true
  end

  if self.moveClippedLine then
    local s = clippedLineSpeed
    local d = clippedLineDirection
    clippedLineX = clippedLineX + dt * s * d
  
    if clippedLineX < -clippedLineOffset then
      clippedLineX = -clippedLineOffset
      self:invertClippedLineMovement()
    end
  
    if clippedLineX > 0 then
      clippedLineX = 0
      self:invertClippedLineMovement()
    end
  end
end

function listManager:draw()
  local list, from, to, y = self:getListingCommons()

  -- debug
  love.graphics.setColor(0, 0, 0, 0.25)
  love.graphics.rectangle('line',
    self.listBounds.x,
    self.listBounds.y,
    self.listBounds.w,
    self.listBounds.h
  )

  love.graphics.stencil(getListStencil(), 'replace', 1) 
  love.graphics.setStencilTest('greater', 0)

  for i = from, to do
    local item = list.items[i]
    if not item then goto continue end
    
    local icon
    local x = ( -- move selected line only (if clipped)
      y == (list.page.indexAtCurrentPage - 1) and
      item.clipped and
      clippedLineX
    ) or 0

    local color = item.color or list.color or colors.white
    if item.isDir then icon = images.icons.folder end
    local iconOffset = self:drawIconAndGetOffset(icon, x, y)
    self:printItemText(item, iconOffset, x, y)
    self:drawListPointer(y)
    self:drawLineExtras(item, y)
    y = y + 1

    ::continue::
  end

  love.graphics.setStencilTest()
end

function listManager:back(value, listsStack, pathStack, currentScreen)
  local currentListsStack = listsStack[currentScreen]
  local currentPathStack = pathStack[currentScreen]

  if #currentListsStack > 1 then
    table.remove(currentListsStack)
    table.remove(currentPathStack)
    self.currentList = currentListsStack[#currentListsStack]
    if currentListsStack == listsStack[_G.screens.systems] and #currentListsStack == 1 then
      _G.systemSelected = nil
    end
  end
end

function listManager:handleLastPage()
  local list, n, totalPages = self:getPaginationCommons()
  local itemsAtCurrentPage = self:getItemsAtCurrentPage()
  if list.page.pageNumber == totalPages then
    if list.page.indexAtCurrentPage > itemsAtCurrentPage then
      list.page.indexAtCurrentPage = itemsAtCurrentPage
    end
    list.index = (totalPages - 1) * self.pageSize + list.page.indexAtCurrentPage
  end
end

function listManager:left()
  local list, n, totalPages = self:getPaginationCommons()
  if totalPages == 1 then return end

  list.index = list.index - self.pageSize
  list.page.pageNumber = list.page.pageNumber - 1

  if list.page.pageNumber < 1 then
    list.page.pageNumber = totalPages
  end
  self:handleLastPage()
  self:resetClippedLine()
end

function listManager:right()
  local list, n, totalPages = self:getPaginationCommons()
  if totalPages == 1 then return end

  list.index = list.index + self.pageSize
  list.page.pageNumber = list.page.pageNumber + 1

  if list.index > n then
    list.index = 1
  end
  if list.page.pageNumber > totalPages then
    list.page.pageNumber = 1
  end
  self:handleLastPage()
  self:resetClippedLine()
end

function listManager:up()
  local list, n, totalPages = self:getPaginationCommons()
  -- internal index
  list.index = list.index - 1
  list.page.indexAtCurrentPage = list.page.indexAtCurrentPage - 1

  if list.index < 1 then
    list.index = n
  end

  -- index to display
  if list.page.indexAtCurrentPage < 1 then
    -- handle first page
    local itemsInCurrentPage = self.pageSize
    if list.page.pageNumber == 1 then
      itemsInCurrentPage = self.pageSize - ((totalPages * self.pageSize) - n)
    end
    
    list.page.indexAtCurrentPage = itemsInCurrentPage
    list.page.pageNumber = list.page.pageNumber - 1

    -- going beyond the last page
    if list.page.pageNumber < 1 then
      list.page.pageNumber = totalPages
    end
  end
  self:resetClippedLine()
end

function listManager:down()
  local list, n, totalPages = self:getPaginationCommons()
  -- internal index
  list.index = list.index + 1
  list.page.indexAtCurrentPage = list.page.indexAtCurrentPage + 1

  if list.index > n then
    list.index = 1
  end

  -- handle last page
  local itemsInCurrentPage = self.pageSize
  if list.page.pageNumber == totalPages then
    itemsInCurrentPage = self.pageSize - ((totalPages * self.pageSize) - n)
  end

  -- index to display
  if list.page.indexAtCurrentPage > itemsInCurrentPage then
    list.page.indexAtCurrentPage = 1
    list.page.pageNumber = list.page.pageNumber + 1

    -- going beyond the last page
    if list.page.pageNumber > totalPages then
      list.page.pageNumber = 1
    end
  end
  self:resetClippedLine()
end

function listManager:performAction(listsStack, pathStack, cb)
  local item = self:getSelectedItem()
  local currentListsStack = listsStack[currentScreen]
  local currentPathStack = pathStack[currentScreen]

  if item.items and #item.items > 0 then
    table.insert(currentListsStack, item)
    table.insert(currentPathStack, item.internalLabel)
    if item.isSystem then -- set selected system (gb, nes, etc.)
      _G.systemSelected = item.internalLabel
    end
    self.currentList = item
    self:resetClippedLine()
  else 
    cb(item)
  end
end

return listManager
