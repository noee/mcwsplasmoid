 WorkerScript.onMessage = function(msg) {

     // { lm: model, role: string }

     let indexes = [...Array(msg.lm.count)].map( (v,i) => i )
     indexes.sort(
                 (a, b) => {
                     let item1 = msg.lm.get(a)
                     let item2 = msg.lm.get(b)
                     if (item1[msg.role] < item2[msg.role])
                        return -1
                     if (item1[msg.role] > item2[msg.role])
                        return 1
                     else
                        return 0
                 })

     let sorted = 0
     while (sorted < indexes.length && sorted === indexes[sorted])
         sorted++

     if (sorted === indexes.length)
         return

     let arr = []
     for (let i = sorted; i < indexes.length; i++) {
         arr.push(Object.assign({}, msg.lm.get(indexes[i])))
//        msg.lm.move(indexes[i], msg.lm.count - 1, 1)
//        msg.lm.insert(indexes[i], { } )
     }
//     msg.lm.remove(sorted, indexes.length - sorted)

     WorkerScript.sendMessage({ results: arr })
//     msg.lm.sync() // crashes
}
