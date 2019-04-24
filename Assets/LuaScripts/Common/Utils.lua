local Vector3 = Vector3
local Mathf = Mathf
local FixAdd = FixMath.add
local FixMul = FixMath.mul
local FixNewVector3 = FixMath.NewFixVector3
local SplitString = CUtil.SplitString

Utils = {
    GetRandPosNew = function(oriPos, minDis, maxDis)
        local tmpMin = minDis * 10000
        local tmpMax = maxDis * 10000
        local x = oriPos.x + Utils.RandomBetween(tmpMin, tmpMax) / 10000
        local y = oriPos.y
        local z = oriPos.z + Utils.RandomBetween(tmpMin, tmpMax) / 10000
        return Vector3.New(x, y, z)
    end,

    RandomBetween = function(min, max)
        return Mathf.Random(min, max)
    end,

    RandPos = function(oriPos, minDis, maxDis)
        if maxDis <= 0 then
            return oriPos
        end

        return Utils.GetRandPosNew(oriPos, minDis, maxDis)
    end,

    MatrixMulPoint = function(matrix, fixv3)
        local x,y,z = fixv3:GetXYZ()
        local v4 = { x, y, z, 1 }
        local calced = {}
        for i = 1, 4 do
            local sum = 0
            local row = matrix[i]

            for j = 1, 4 do
                sum = FixAdd(sum, FixMul(row[j], v4[j]))
            end

            if i < 4 then
                calced[i] = sum
            end
        end

        return FixNewVector3(calced[1], calced[2], calced[3])
    end,

    MatrixMulVector = function(matrix, fixv3)
        local x,y,z = fixv3:GetXYZ()
        local v4 = { x, y, z, 0 }
        local calced = {}
        for i = 1, 4 do
            local sum = 0
            local row = matrix[i]

            for j = 1, 4 do
                sum = FixAdd(sum, FixMul(row[j], v4[j]))
            end

            if i < 4 then
                calced[i] = sum
            end
        end

        return FixNewVector3(calced[1], calced[2], calced[3])
    end,

    IterPbRepeated = function(t)
        return ipairs(t)
    end,

    CountPbRepeated = function(t)
        return #(t)
    end,

    GetPbRepeated = function(t, i)
        return t[i]
    end,

    GetExecuteTime = function(start)
        return string.format("%.0f", (os.clock() - start) * 1000)
    end,

    GetBuZhenIDByBattleType = function(battleType)
        if battleType > 10000 then
            return battleType
        end
        
        return battleType + 1000
    end,

    GetLieZhuanBuZhenIDByBattleType = function(battleType, countryId)
        return countryId * 10000 + battleType + 1000
    end,

    GetBattleTypeByBuZhenID = function(buzhenID)
        return buzhenID - 1000
    end,

    IsWujiang = function(wujiangID)
        return wujiangID >= 1000 and wujiangID <= 9999
    end,

    IsDragon = function(dragonID)
        return dragonID == 3601 or dragonID == 3602 or dragonID == 3603 or dragonID == 3606
    end,
    
    ParseHttpMsg = function(msg)
        if not msg or msg == '' then
            return
        end

        local ret = {}
        local paramList = SplitString(msg, '&')
        for _, param in ipairs(paramList) do
            local keyAndValue = SplitString(param, '=')
            if #keyAndValue >= 2 then
                ret[keyAndValue[1]] = keyAndValue[2]
            end
        end
        return ret
    end,
}
